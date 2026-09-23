# Chúc Mừng Bạn Đã Hoàn Thành Lab 4!

Bạn đã xây dựng thành công một hệ thống **Nginx Reverse Proxy** hoàn chỉnh với **Load Balancing** và **Connection Pooling** — kiến trúc tiêu chuẩn để vận hành mọi hệ thống web production trong DevOps.

---

## Bảng Tra Cứu Lệnh Nhanh (Nginx Proxy & Load Balancing Cheat Sheet)

### Reverse Proxy

| Mục Đích | Cấu Hình | Ý Nghĩa |
|---|---|---|
| **Chuyển tiếp request** | `proxy_pass http://backend;` | Forward request tới backend |
| **Bảo toàn Host** | `proxy_set_header Host $host;` | Giữ nguyên tên miền gốc |
| **Truyền IP client** | `proxy_set_header X-Real-IP $remote_addr;` | Backend nhận IP thật của client |
| **Chuỗi proxy** | `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;` | Ghi nhận toàn bộ IP đã đi qua |
| **Giao thức gốc** | `proxy_set_header X-Forwarded-Proto $scheme;` | Phân biệt http/https |

### Load Balancing

| Thuật Toán | Directive | Khi Nào Dùng |
|---|---|---|
| **Round Robin** | (mặc định) | Backend đồng đều, không cần sticky |
| **Weighted** | `weight=N` | Backend mạnh/yếu khác nhau |
| **Least Connections** | `least_conn;` | Thời gian xử lý request không đồng đều |
| **IP Hash** | `ip_hash;` | Cần session sticky (giỏ hàng, đăng nhập) |
| **Backup server** | `server ... backup;` | Server dự phòng khi server chính down |
| **Health check** | `max_fails=3 fail_timeout=30s;` | Tự động loại backend lỗi |

### Connection Pooling & Tuning

| Tham Số | Giá Trị Khuyến Nghị | Ý Nghĩa |
|---|---|---|
| `keepalive 32` | 32–64 | Số idle connections trong pool tới backend |
| `proxy_http_version 1.1` | Bắt buộc | HTTP/1.1 hỗ trợ persistent connection |
| `proxy_set_header Connection ""` | Bắt buộc | Xóa header "Connection: close" |
| `keepalive_requests 1000` | 1000–10000 | Số request tối đa trên 1 connection |
| `keepalive_timeout 60s` | 60–120s | Thời gian giữ idle connection |
| `proxy_connect_timeout 5s` | 5–10s | Timeout kết nối tới backend |
| `proxy_read_timeout 30s` | 30–60s | Timeout chờ response |

### Quản Lý Nginx

| Mục Đích | Lệnh |
|---|---|
| **Kiểm tra cú pháp** | `nginx -t` |
| **Reload** (zero-downtime) | `nginx -s reload` |
| **Restart** | `systemctl restart nginx` |
| **Xem access log** | `tail -f /var/log/nginx/access.log` |
| **Xem error log** | `tail -f /var/log/nginx/error.log` |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Cấu hình được Nginx Reverse Proxy chuyển tiếp request tới backend bằng `proxy_pass`.
- [x] Thiết lập `proxy_set_header` để bảo toàn IP client (`X-Real-IP`, `X-Forwarded-For`).
- [x] Triển khai upstream block với nhiều backend server.
- [x] Phân biệt và áp dụng 4 thuật toán Load Balancing: Round Robin, Weighted, Least Connections, IP Hash.
- [x] Cấu hình Health Check (`max_fails`, `fail_timeout`) và Backup Server.
- [x] Bật Connection Pooling (`keepalive`) với `proxy_http_version 1.1` bắt buộc.
- [x] Hiểu tại sao `proxy_set_header Connection ""` là bắt buộc khi dùng keepalive.
- [x] Tuning các tham số timeout và keepalive phù hợp cho production.
- [x] Xây dựng được cấu hình Nginx hoàn chỉnh kết hợp Reverse Proxy + Load Balancing + Connection Pooling.

---

## Bước Tiếp Theo

Bây giờ bạn đã nắm vững cách Nginx hoạt động như Reverse Proxy, Load Balancer và Connection Pool Manager. Khi hệ thống đã hoạt động, nhiệm vụ tiếp theo của người làm DevOps là **giám sát liên tục tài nguyên và đảm bảo tính sẵn sàng của hạ tầng**.

Hãy tiếp tục với **Lab 5: Giám Sát Tài Nguyên Máy Chủ & Cảnh Báo Tự Động Với Bash Script** để học cách:
- Bóc tách chỉ số CPU, RAM, Disk bằng các tiện ích Linux CLI.
- Thiết lập logic cảnh báo ngưỡng (Warning & Critical).
- Gửi cảnh báo tự động qua Webhook và lập lịch tự động với Crontab kết hợp thử nghiệm tải cao (Stress Testing).

