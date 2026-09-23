# Buoc 3: Cau Hinh Nginx HTTPS Voi Self-Signed Certificate

Sau khi da hieu cach TLS hoat dong va biet cach kiem tra certificate, bay gio ban se tu tay **tao certificate** va **cau hinh Nginx phuc vu HTTPS** tren cong 443. Day la ky nang thiet yeu khi thiet lap moi truong staging, internal API, hoac bat ky dich vu nao can ma hoa truoc khi co certificate chinh thuc tu Let's Encrypt.

---

## 1. Tao Self-Signed Certificate Bang `openssl`

Lenh sau tao mot cap khoa (private key + certificate) tu ky, hieu luc 365 ngay:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt \
  -subj "/C=VN/ST=HCM/L=HCM/O=DevOps Lab/CN=lab.local"
```{{exec}}

Giai thich tung tham so:
- `-x509`: Tao certificate tu ky (khong can gui CSR cho CA).
- `-nodes`: Khong ma hoa private key bang password (thuan tien cho tu dong hoa).
- `-days 365`: Thoi gian hieu luc 1 nam.
- `-newkey rsa:2048`: Tao khoa RSA 2048-bit moi.
- `-keyout`: Duong dan luu private key.
- `-out`: Duong dan luu certificate.
- `-subj`: Thong tin subject (quoc gia, thanh pho, to chuc, ten mien).

### Xac minh certificate vua tao

```bash
openssl x509 -in /etc/ssl/certs/nginx-selfsigned.crt -noout -subject -issuer -dates
```{{exec}}

Quan sat: **subject** va **issuer** giong nhau — dac trung cua Self-Signed Certificate (tu ky cho chinh minh).

---

## 2. Cau Hinh Nginx Lang Nghe HTTPS Tren Cong 443

Truoc tien, xoa cau hinh mac dinh cua Nginx de tranh xung dot:

```bash
rm -f /etc/nginx/sites-enabled/default
```{{exec}}

Tao file cau hinh HTTPS moi tai `/etc/nginx/conf.d/ssl.conf`:

```bash
cat << 'EOF' > /etc/nginx/conf.d/ssl.conf
# Server block HTTPS (cong 443)
server {
    listen 443 ssl;
    server_name lab.local;

    # Duong dan toi certificate va private key
    ssl_certificate     /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    # Chi cho phep cac phien ban TLS an toan
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        return 200 "HTTPS dang hoat dong! Ket noi duoc ma hoa boi TLS.\n";
        add_header Content-Type text/plain;
    }
}

# Server block HTTP (cong 80) - Redirect sang HTTPS
server {
    listen 80;
    server_name lab.local;

    # Chuyen huong vinh vien (301) moi request HTTP sang HTTPS
    return 301 https://$host$request_uri;
}
EOF
```{{exec}}

### Giai thich cac chi thi SSL quan trong

| Chi Thi | Muc Dich |
|---|---|
| `listen 443 ssl` | Lang nghe cong 443 va bat che do SSL/TLS |
| `ssl_certificate` | Duong dan toi file certificate (public key) |
| `ssl_certificate_key` | Duong dan toi file private key (bao mat, khong duoc lo) |
| `ssl_protocols TLSv1.2 TLSv1.3` | Chi chap nhan TLS 1.2 va 1.3 (vo hieu hoa TLS 1.0/1.1 khong an toan) |
| `ssl_ciphers HIGH:!aNULL:!MD5` | Chi dung cipher manh, loai bo cipher yeu (NULL, MD5) |
| `return 301 https://...` | Redirect vinh vien tu HTTP sang HTTPS |

---

## 3. Kiem Tra Cu Phap va Khoi Dong Nginx

Luon kiem tra cu phap truoc khi khoi dong hoac reload Nginx:

```bash
nginx -t
```{{exec}}

Khoi dong Nginx:

```bash
systemctl start nginx
```{{exec}}

Kiem tra trang thai dang chay:

```bash
systemctl status nginx --no-pager
```{{exec}}

---

## 4. Kiem Tra HTTPS Hoat Dong

### Gui request HTTPS voi `curl`

Vi su dung Self-Signed Certificate (khong duoc CA tin tuong), can them tham so `-k` (insecure) de bo qua kiem tra certificate:

```bash
curl -k https://localhost
```{{exec}}

Ban se thay: `HTTPS dang hoat dong! Ket noi duoc ma hoa boi TLS.`

### Quan sat chi tiet bat tay TLS

```bash
curl -kv https://localhost 2>&1 | head -20
```{{exec}}

Chu y cac dong:
- `* SSL connection using TLSv1.3 / ...` — Xac nhan TLS 1.3 dang duoc su dung.
- `* Server certificate:` — Thong tin Self-Signed Certificate cua ban.
- `* subject: C=VN; ST=HCM; ...` — Thong tin subject ban da khai bao.

### Kiem tra HTTP redirect sang HTTPS

```bash
curl -v http://localhost 2>&1 | grep -E "< HTTP|< Location"
```{{exec}}

Ban se thay:
- `< HTTP/1.1 301 Moved Permanently` — Ma chuyen huong vinh vien.
- `< Location: https://localhost/` — Dia chi dich la HTTPS.

### Kiem tra certificate tu Nginx bang `openssl s_client`

```bash
echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```{{exec}}

---

## 5. SSL Termination La Gi?

Trong kien truc san xuat, **SSL Termination** la ky thuat giai ma TLS tai tang Reverse Proxy (Nginx) roi chuyen tiep request bang HTTP thuan toi backend:

```text
Client ──── HTTPS (TLS encrypted) ────> [ Nginx - SSL Termination ]
                                                    |
                                          HTTP (plaintext, noi bo)
                                                    |
                                                    v
                                            [ Backend App ]
                                           (Node.js, Python, Go)
```

**Loi ich:**
- Backend khong can xu ly TLS, giam tai CPU.
- Tap trung quan ly certificate tai mot diem duy nhat (Nginx).
- De dang gia han certificate (Let's Encrypt auto-renewal) ma khong can restart backend.
- Giao tiep noi bo (Nginx <-> Backend) co the dung HTTP neu ca hai nam trong cung mot mang private (VPC/Pod network).

---

## 6. Thu Thach & Xac Thuc (Verification)

Hay dam bao Nginx cua ban dang lang nghe va phuc vu HTTPS tren cong 443:

1. Kiem tra Nginx dang listen tren cong 443:
   ```bash
   ss -tlpn | grep 443
   ```

2. Gui request HTTPS va xac nhan nhan duoc phan hoi thanh cong:
   ```bash
   curl -k https://localhost
   ```

3. Bam nut **Check** ben duoi thanh dieu khien de he thong tu dong xac thuc!
