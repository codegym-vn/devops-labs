# Chuc Mung Ban Da Hoan Thanh Lab 2!

Ban da thanh thao ky nang phan tich giao thuc **HTTP/HTTPS** va cau hinh **SSL/TLS Certificate** cho Nginx — nhung ky nang thiet yeu de bao mat va van hanh moi he thong web trong moi truong DevOps.

---

## Bang Tra Cuu Lenh Nhanh (HTTP/HTTPS & SSL/TLS Cheat Sheet)

| Muc Dich | Lenh Thuc Hien | Y Nghia |
|---|---|---|
| **Phan tich HTTP chi tiet** | `curl -v <URL>` | Xem toan bo request/response bao gom headers va TLS handshake |
| **Chi xem Response Headers** | `curl -I <URL>` | Gui HEAD request, lay headers ma khong tai body |
| **Lay HTTP status code** | `curl -o /dev/null -s -w "%{http_code}" <URL>` | Xuat duy nhat ma status code (200, 301, 404, 502...) |
| **Gui POST voi JSON** | `curl -X POST -H "Content-Type: application/json" -d '{}' <URL>` | Mo phong API call hoac Webhook |
| **Kiem tra certificate** | `openssl s_client -connect <host>:443` | Ket noi TLS va xem toan bo certificate chain |
| **Xem subject/issuer/ngay** | `openssl s_client ... \| openssl x509 -noout -subject -issuer -dates` | Trich xuat thong tin certificate quan trong |
| **Kiem tra ngay het han** | `openssl s_client ... \| openssl x509 -noout -enddate` | Theo doi ngay het han certificate (monitoring) |
| **Tao Self-Signed Cert** | `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key -out cert` | Tao certificate tu ky cho dev/test |
| **Cau hinh Nginx HTTPS** | `listen 443 ssl; ssl_certificate ...; ssl_certificate_key ...;` | Bat HTTPS tren Nginx |
| **Kiem tra cu phap Nginx** | `nginx -t` | Kiem tra loi cau hinh truoc khi reload/restart |
| **Reload Nginx** | `nginx -s reload` | Nap lai cau hinh khong ngat ket noi (Zero-Downtime) |
| **HTTP -> HTTPS Redirect** | `return 301 https://$host$request_uri;` | Chuyen huong vinh vien tu HTTP sang HTTPS |

---

## Checklist Tu Danh Gia Nang Luc

- [x] Hieu cau truc HTTP Request (Method, URL, Headers, Body) va HTTP Response (Status Code, Headers, Body).
- [x] Phan biet duoc cac nhom HTTP Status Code: 2xx (thanh cong), 3xx (redirect), 4xx (loi client), 5xx (loi server).
- [x] Su dung `curl -v` de phan tich chi tiet qua trinh giao tiep HTTP va TLS.
- [x] Hieu 3 muc tieu bao mat cua HTTPS: Ma hoa, Xac thuc, Toan ven.
- [x] Mo ta duoc quy trinh bat tay TLS: ClientHello -> ServerHello -> Certificate -> Key Exchange -> Encrypted Data.
- [x] Su dung `openssl s_client` de kiem tra certificate thuc te: subject, issuer, ngay het han, certificate chain.
- [x] Tao duoc Self-Signed Certificate bang `openssl req`.
- [x] Cau hinh thanh cong Nginx phuc vu HTTPS tren cong 443 voi SSL/TLS.
- [x] Thiet lap HTTP-to-HTTPS Redirect (301) tren Nginx.
- [x] Hieu khai niem SSL Termination va loi ich khi ap dung trong kien truc Reverse Proxy.

---

## Buoc Tiep Theo

Bay gio ban da nam vung cach HTTP hoat dong, cach bao mat bang HTTPS/TLS, va cach cau hinh SSL cho Nginx. Day la nen tang de ban tien toi cac chu de nang cao hon nhu:
- **Reverse Proxy & Load Balancing**: Dieu phoi traffic nguoi dung vao cum backend microservices.
- **Let's Encrypt & Certbot**: Tu dong hoa cap phat va gia han certificate mien phi cho production.
- **Kubernetes Ingress + TLS**: Quan ly certificate va routing cho cum container.
