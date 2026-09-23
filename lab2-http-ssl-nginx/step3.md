# Bước 3: Cấu Hình Nginx HTTPS Với Self-Signed Certificate

Sau khi đã hiểu cách TLS hoạt động và biết cách kiểm tra certificate, bây giờ bạn sẽ tự tay **tạo certificate** và **cấu hình Nginx phục vụ HTTPS** trên cổng 443. Đây là kỹ năng thiết yếu khi thiết lập môi trường staging, internal API, hoặc bất kỳ dịch vụ nào cần mã hóa trước khi có certificate chính thức từ Let's Encrypt.

---

## 1. Tạo Self-Signed Certificate Bằng `openssl`

Lệnh sau tạo một cặp khóa (private key + certificate) tự ký, hiệu lực 365 ngày:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=VN/ST=HCM/L=HCM/O=DevOps Lab/CN=lab.local"
```{{exec}}

Giải thích từng tham số:
- `-x509`: Tạo certificate tự ký (không cần gửi CSR cho CA).
- `-nodes`: Không mã hóa private key bằng password (thuận tiện cho tự động hóa).
- `-days 365`: Thời gian hiệu lực 1 năm.
- `-newkey rsa:2048`: Tạo khóa RSA 2048-bit mới.
- `-keyout`: Đường dẫn lưu private key.
- `-out`: Đường dẫn lưu certificate.
- `-subj`: Thông tin subject (quốc gia, thành phố, tổ chức, tên miền).

### Xác minh certificate vừa tạo

```bash
openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -subject -issuer -dates
```{{exec}}

Quan sát: **subject** và **issuer** giống nhau — đặc trưng của Self-Signed Certificate (tự ký cho chính mình).

---

## 2. Cấu Hình Nginx Lắng Nghe HTTPS Trên Cổng 443

Trước tiên, xóa cấu hình mặc định của Nginx để tránh xung đột:

```bash
rm -f /etc/nginx/sites-enabled/default
```{{exec}}

Tạo file cấu hình HTTPS mới tại `/etc/nginx/conf.d/ssl.conf`:

```bash
cat << 'EOF' > /etc/nginx/conf.d/ssl.conf
# Server block HTTPS (cổng 443)
server {
    listen 443 ssl;
    server_name lab.local;

    # Đường dẫn tới certificate và private key
    ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    # Chỉ cho phép các phiên bản TLS an toàn
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        return 200 "HTTPS dang hoat dong! Ket noi duoc ma hoa boi TLS.\n";
        add_header Content-Type text/plain;
    }
}

# Server block HTTP (cổng 80) - Redirect sang HTTPS
server {
    listen 80;
    server_name lab.local;

    # Chuyển hướng vĩnh viễn (301) mọi request HTTP sang HTTPS
    return 301 https://$host$request_uri;
}
EOF
```{{exec}}

### Giải thích các chỉ thị SSL quan trọng

| Chỉ Thị | Mục Đích |
|---|---|
| `listen 443 ssl` | Lắng nghe cổng 443 và bật chế độ SSL/TLS |
| `ssl_certificate` | Đường dẫn tới file certificate (public key) |
| `ssl_certificate_key` | Đường dẫn tới file private key (bảo mật, không được lộ) |
| `ssl_protocols TLSv1.2 TLSv1.3` | Chỉ chấp nhận TLS 1.2 và 1.3 (vô hiệu hóa TLS 1.0/1.1 không an toàn) |
| `ssl_ciphers HIGH:!aNULL:!MD5` | Chỉ dùng cipher mạnh, loại bỏ cipher yếu (NULL, MD5) |
| `return 301 https://...` | Redirect vĩnh viễn từ HTTP sang HTTPS |

---

## 3. Kiểm Tra Cú Pháp và Khởi Động Nginx

Luôn kiểm tra cú pháp trước khi khởi động hoặc reload Nginx:

```bash
nginx -t
```{{exec}}

Khởi động Nginx:

```bash
systemctl start nginx
```{{exec}}

Kiểm tra trạng thái đang chạy:

```bash
systemctl status nginx --no-pager
```{{exec}}

---

## 4. Kiểm Tra HTTPS Hoạt Động

### Gửi request HTTPS với `curl`

Vì sử dụng Self-Signed Certificate (không được CA tin tưởng), cần thêm tham số `-k` (insecure) để bỏ qua kiểm tra certificate:

```bash
curl -k https://localhost
```{{exec}}

Bạn sẽ thấy: `HTTPS dang hoat dong! Ket noi duoc ma hoa boi TLS.`

### Quan sát chi tiết bắt tay TLS

```bash
curl -kv https://localhost 2>&1 | head -20
```{{exec}}

Chú ý các dòng:
- `* SSL connection using TLSv1.3 / ...` — Xác nhận TLS 1.3 đang được sử dụng.
- `* Server certificate:` — Thông tin Self-Signed Certificate của bạn.
- `* subject: C=VN; ST=HCM; ...` — Thông tin subject bạn đã khai báo.

### Kiểm tra HTTP redirect sang HTTPS

```bash
curl -v http://localhost 2>&1 | grep -E "< HTTP|< Location"
```{{exec}}

Bạn sẽ thấy:
- `< HTTP/1.1 301 Moved Permanently` — Mã chuyển hướng vĩnh viễn.
- `< Location: https://localhost/` — Địa chỉ đích là HTTPS.

### Kiểm tra certificate từ Nginx bằng `openssl s_client`

```bash
echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

---

## 5. SSL Termination Là Gì?

Trong kiến trúc sản xuất, **SSL Termination** là kỹ thuật giải mã TLS tại tầng Reverse Proxy (Nginx) rồi chuyển tiếp request bằng HTTP thuần tới backend:

```text
Client ──── HTTPS (TLS encrypted) ────> [ Nginx - SSL Termination ]
                                                    |
                                          HTTP (plaintext, nội bộ)
                                                    |
                                                    v
                                            [ Backend App ]
                                           (Node.js, Python, Go)
```

**Lợi ích:**
- Backend không cần xử lý TLS, giảm tải CPU.
- Tập trung quản lý certificate tại một điểm duy nhất (Nginx).
- Dễ dàng gia hạn certificate (Let's Encrypt auto-renewal) mà không cần restart backend.
- Giao tiếp nội bộ (Nginx <-> Backend) có thể dùng HTTP nếu cả hai nằm trong cùng một mạng private (VPC/Pod network).

---

## 6. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo Nginx của bạn đang lắng nghe và phục vụ HTTPS trên cổng 443:

1. Kiểm tra Nginx đang listen trên cổng 443:
   ```bash
   ss -tlpn | grep 443
   ```

2. Gửi request HTTPS và xác nhận nhận được phản hồi thành công:
   ```bash
   curl -k https://localhost
   ```

3. Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
