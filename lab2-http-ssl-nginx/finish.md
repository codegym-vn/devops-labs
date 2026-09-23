# Chúc Mừng Bạn Đã Hoàn Thành Lab 2!

Bạn đã thành thạo kỹ năng phân tích giao thức **HTTP/HTTPS** và cấu hình **SSL/TLS Certificate** cho Nginx — những kỹ năng thiết yếu để bảo mật và vận hành mọi hệ thống web trong môi trường DevOps.

---

## Bảng Tra Cứu Lệnh Nhanh (HTTP/HTTPS & SSL/TLS Cheat Sheet)

| Mục Đích | Lệnh Thực Hiện | Ý Nghĩa |
|---|---|---|
| **Phân tích HTTP chi tiết** | `curl -v <URL>` | Xem toàn bộ request/response bao gồm headers và TLS handshake |
| **Chỉ xem Response Headers** | `curl -I <URL>` | Gửi HEAD request, lấy headers mà không tải body |
| **Lấy HTTP status code** | `curl -o /dev/null -s -w "%{http_code}" <URL>` | Xuất duy nhất mã status code (200, 301, 404, 502...) |
| **Gửi POST với JSON** | `curl -X POST -H "Content-Type: application/json" -d '{}' <URL>` | Mô phỏng API call hoặc Webhook |
| **Kiểm tra certificate** | `openssl s_client -connect <host>:443` | Kết nối TLS và xem toàn bộ certificate chain |
| **Xem subject/issuer/ngày** | `openssl s_client ... \| openssl x509 -noout -subject -issuer -dates` | Trích xuất thông tin certificate quan trọng |
| **Kiểm tra ngày hết hạn** | `openssl s_client ... \| openssl x509 -noout -enddate` | Theo dõi ngày hết hạn certificate (monitoring) |
| **Tạo Self-Signed Cert** | `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key -out cert` | Tạo certificate tự ký cho dev/test |
| **Cấu hình Nginx HTTPS** | `listen 443 ssl; ssl_certificate ...; ssl_certificate_key ...;` | Bật HTTPS trên Nginx |
| **Kiểm tra cú pháp Nginx** | `nginx -t` | Kiểm tra lỗi cấu hình trước khi reload/restart |
| **Reload Nginx** | `nginx -s reload` | Nạp lại cấu hình không ngắt kết nối (Zero-Downtime) |
| **HTTP -> HTTPS Redirect** | `return 301 https://$host$request_uri;` | Chuyển hướng vĩnh viễn từ HTTP sang HTTPS |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Hiểu cấu trúc HTTP Request (Method, URL, Headers, Body) và HTTP Response (Status Code, Headers, Body).
- [x] Phân biệt được các nhóm HTTP Status Code: 2xx (thành công), 3xx (redirect), 4xx (lỗi client), 5xx (lỗi server).
- [x] Sử dụng `curl -v` để phân tích chi tiết quá trình giao tiếp HTTP và TLS.
- [x] Hiểu 3 mục tiêu bảo mật của HTTPS: Mã hóa, Xác thực, Toàn vẹn.
- [x] Mô tả được quy trình bắt tay TLS: ClientHello -> ServerHello -> Certificate -> Key Exchange -> Encrypted Data.
- [x] Sử dụng `openssl s_client` để kiểm tra certificate thực tế: subject, issuer, ngày hết hạn, certificate chain.
- [x] Tạo được Self-Signed Certificate bằng `openssl req`.
- [x] Cấu hình thành công Nginx phục vụ HTTPS trên cổng 443 với SSL/TLS.
- [x] Thiết lập HTTP-to-HTTPS Redirect (301) trên Nginx.
- [x] Hiểu khái niệm SSL Termination và lợi ích khi áp dụng trong kiến trúc Reverse Proxy.

---

## Bước Tiếp Theo

Bây giờ bạn đã nắm vững cách HTTP hoạt động, cách bảo mật bằng HTTPS/TLS, và cách cấu hình SSL cho Nginx. Hãy chuyển sang **Lab 3: SSH Hardening, Port Forwarding & Tường Lửa UFW** để học cách gia cố bảo mật truy cập server, tạo đường hầm mã hóa và kiểm soát traffic mạng!

