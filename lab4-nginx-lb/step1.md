# Bước 1: Reverse Proxy - Chuyển Tiếp Request & Bảo Toàn IP Client

**Reverse Proxy** là mô hình mà client gửi request tới Nginx, Nginx chuyển tiếp (forward) request đó tới backend server phía sau, nhận response rồi trả lại cho client. Client không biết và không cần biết backend nằm ở đâu.

> **Lưu ý môi trường:** Hệ thống Killercoda đã tự động cài đặt sẵn Nginx và khởi chạy 3 backend giả lập trên port 8001, 8002, 8003. Bạn có thể bắt đầu gõ lệnh ngay.

---

## 1. Kiểm Tra 3 Backend Đang Chạy

Trước tiên, xác nhận 3 backend giả lập đã hoạt động:

```bash
curl http://localhost:8001
curl http://localhost:8002
curl http://localhost:8003
```{{exec}}

Mỗi backend trả về nội dung khác nhau (`Response from Backend 8001/8002/8003`) để bạn dễ nhận biết request đang được xử lý bởi backend nào.

---

## 2. Reverse Proxy Là Gì?

```text
  Không có Reverse Proxy:               Có Reverse Proxy:

  Client ──> Backend:8001               Client ──> Nginx:80 ──> Backend:8001
  Client ──> Backend:8002               (Client chỉ biết Nginx,
  Client ──> Backend:8003                không biết backend tồn tại)
  (Client phải biết IP                  
   từng backend)
```

**Lợi ích của Reverse Proxy:**

| Lợi Ích | Giải Thích |
|---|---|
| **Bảo mật** | Ẩn IP và port thật của backend khỏi Internet |
| **SSL Termination** | Tập trung quản lý certificate tại Nginx (đã học ở Lab 2) |
| **Load Balancing** | Phân phối request qua nhiều backend (sẽ học ở Bước 2) |
| **Caching** | Nginx cache response để giảm tải cho backend |
| **Compression** | Nginx nén response (gzip) trước khi trả về client |

---

## 3. Cấu Hình Nginx Reverse Proxy Cơ Bản

Xóa cấu hình Nginx mặc định:

```bash
rm -f /etc/nginx/sites-enabled/default
```{{exec}}

Tạo cấu hình Reverse Proxy tại `/etc/nginx/conf.d/proxy.conf`:

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
server {
    listen 80;
    server_name localhost;

    location / {
        # Chuyen tiep tat ca request toi backend 8001
        proxy_pass http://127.0.0.1:8001;
    }
}
EOF
```{{exec}}

Kiểm tra cú pháp và khởi động Nginx:

```bash
nginx -t && systemctl start nginx
```{{exec}}

Gửi request tới Nginx (port 80) và kiểm tra response:

```bash
curl http://localhost
```{{exec}}

Kết quả `Response from Backend 8001` — Nginx đã nhận request trên port 80 và chuyển tiếp thành công tới backend 8001.

---

## 4. Bảo Toàn IP Client Qua HTTP Headers

Mặc định, khi Nginx chuyển tiếp request, backend chỉ thấy **IP của Nginx** (127.0.0.1) thay vì IP thật của client. Đây là vấn đề lớn vì:
- **Logging**: Access log của backend ghi sai IP.
- **Rate Limiting**: Không thể giới hạn theo IP client thật.
- **Geolocation**: Không xác định được vị trí người dùng.

### Giải pháp: `proxy_set_header`

Cập nhật cấu hình Nginx để truyền thông tin IP client xuống backend:

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:8001;

        # Bao toan thong tin client goc
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```{{exec}}

Reload Nginx (không ngắt kết nối hiện có):

```bash
nginx -s reload
```{{exec}}

### Bảng giải thích các Header

| Header | Biến Nginx | Mục Đích | Ví Dụ |
|---|---|---|---|
| `Host` | `$host` | Tên miền gốc mà client gửi tới | `api.example.com` |
| `X-Real-IP` | `$remote_addr` | IP thật của client (1 IP duy nhất) | `203.0.113.50` |
| `X-Forwarded-For` | `$proxy_add_x_forwarded_for` | Chuỗi IP đã đi qua các proxy | `203.0.113.50, 10.0.0.1` |
| `X-Forwarded-Proto` | `$scheme` | Giao thức gốc (http hoặc https) | `https` |

Kiểm tra Reverse Proxy vẫn hoạt động:

```bash
curl -v http://localhost 2>&1 | grep -E "< HTTP|Response"
```{{exec}}

---

## 5. Các Chỉ Thị Proxy Timeout Quan Trọng

Khi backend xử lý chậm hoặc không phản hồi, Nginx cần biết chờ bao lâu trước khi timeout:

| Chỉ Thị | Mặc Định | Ý Nghĩa |
|---|---|---|
| `proxy_connect_timeout` | 60s | Thời gian chờ kết nối TCP tới backend |
| `proxy_read_timeout` | 60s | Thời gian chờ backend trả response |
| `proxy_send_timeout` | 60s | Thời gian chờ gửi request body tới backend |

> **Mẹo DevOps:** Trong production, nên giảm `proxy_connect_timeout` xuống 5-10 giây. Nếu backend không phản hồi trong 5 giây, khả năng cao nó đã lỗi — chờ thêm chỉ lãng phí tài nguyên và làm chậm trải nghiệm người dùng.

---

## 6. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo Nginx Reverse Proxy đang hoạt động:

1. Truy cập `http://localhost` (port 80) phải trả về nội dung từ backend 8001.
2. Cấu hình phải có `proxy_set_header X-Real-IP` để bảo toàn IP client.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
