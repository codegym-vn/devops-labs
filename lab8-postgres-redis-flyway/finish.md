# Chúc Mừng Bạn Đã Hoàn Thành Lab 8!

Bạn đã xây dựng và tích hợp thành công kiến trúc hạ tầng dữ liệu hoàn chỉnh chuẩn DevOps: từ việc cấu hình kết nối an toàn qua **Biến Môi Trường (Environment Variables)** và **Connection Pooling**, làm chủ quy trình **Database Migration as Code** với **Flyway**, kiểm tra toàn diện **tính toàn vẹn CSDL sau migration**, cho đến việc áp dụng mô hình bộ nhớ đệm **Cache-Aside Pattern** với Redis.

---

## Bảng Tra Cứu Nhanh Lệnh CSDL, Cache & Flyway (DevOps Database Cheat Sheet)

### 1. PostgreSQL & Connection Management

| Mục Đích | Lệnh / Cấu Hình | Giải Thích |
|---|---|---|
| **Xem phiên bản** | `psql -c "SELECT version();"` | Kiểm tra kết nối và version PostgreSQL |
| **Xem kết nối hiện tại** | `psql -c "\conninfo"` | Kiểm tra host, port, user và database đang dùng |
| **Tạo user bảo mật** | `CREATE USER <name> WITH PASSWORD '<pass>';` | Tạo tài khoản người dùng ứng dụng riêng |
| **Cấp quyền database** | `GRANT ALL PRIVILEGES ON DATABASE <db> TO <user>;` | Phân quyền truy cập |
| **Chuỗi kết nối chuẩn** | `postgresql://<user>:<pass>@<host>:5432/<db>` | Định dạng chuẩn nạp qua biến môi trường |

### 2. Redis In-Memory Cache & TTL

| Mục Đích | Lệnh / Cú Pháp | Giải Thích |
|---|---|---|
| **Kiểm tra kết nối** | `redis-cli PING` | Phản hồi `PONG` nếu server hoạt động |
| **Ghi kèm thời gian sống** | `redis-cli SET <key> <val> EX <giây>` | Lưu key và tự động xóa sau N giây |
| **Đọc dữ liệu** | `redis-cli GET <key>` | Lấy giá trị chuỗi từ bộ nhớ RAM |
| **Kiểm tra TTL** | `redis-cli TTL <key>` | Xem số giây còn lại trước khi key hết hạn |
| **Xóa key thủ công** | `redis-cli DEL <key>` | Thu hồi dữ liệu cache ngay lập tức |

### 3. Flyway Database Migration as Code

| Mục Đích | Lệnh / Quy Ước | Giải Thích |
|---|---|---|
| **Quy ước tên file** | `V<Version>__<Description>.sql` | Lưu ý bắt buộc có 2 dấu gạch dưới `__` |
| **Xem trạng thái migration** | `flyway info` | Bảng tổng hợp trạng thái các bản cập nhật |
| **Thực thi migration** | `flyway migrate` | Áp dụng tuần tự các script mới vào CSDL |
| **Kiểm tra tính toàn vẹn** | `flyway validate` | So khớp checksum chống sửa đổi file cũ |
| **Bảng lịch sử hệ thống** | `SELECT * FROM flyway_schema_history;` | Nơi Flyway ghi nhận lịch sử và checksum |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Áp dụng nguyên tắc 12-Factor App: Quản lý thông tin chứng thực CSDL qua file biến môi trường `.env`.
- [x] Hiểu sâu sắc vai trò của Connection Pooling trong việc tối ưu hiệu năng và ngăn ngừa cạn kiệt tài nguyên trên PostgreSQL.
- [x] Nắm vững các lệnh cốt lõi của PostgreSQL (`psql`) và Redis (`redis-cli`).
- [x] Hiểu rõ cơ chế Database Migration as Code và quy ước đặt tên file của Flyway.
- [x] Sử dụng thành thạo bộ 3 lệnh `flyway info`, `flyway migrate`, và `flyway validate`.
- [x] Kiểm tra được tính toàn vẹn của kết nối và dữ liệu sau migration (Foreign Key constraints và Checksum validation).
- [x] Triển khai thành thạo mô hình Cache-Aside Pattern để tăng tốc độ phản hồi của ứng dụng gấp 30 lần.

## Bước Tiếp Theo

Tiếp tục hoàn thiện kỹ năng quản trị Docker chuyên nghiệp trong môi trường Production với bài thực hành tiếp theo:
- **Lab 9**: [Nhập Môn Docker CLI, Cấu Trúc Image Layers & Tương Tác Container](/lab9-docker-cli-fundamentals)

---

## Tổng Kết Chuỗi Bài Thực Hành DevOps & Networking Labs

Bạn đã hoàn thành 8 chặng đường quan trọng và sẵn sàng bước vào bài thực hành nâng cao về Docker:
1. **Lab 1**: TCP/IP, Subnetting, Routing & DNS Troubleshooting
2. **Lab 2**: HTTP/HTTPS Protocols, TLS Handshake & Nginx SSL Configuration
3. **Lab 3**: SSH Hardening, Tunneling Port Forwarding & UFW Firewall
4. **Lab 4**: Nginx Reverse Proxy, Load Balancing Algorithms & Connection Pooling
5. **Lab 5**: Server Resource Monitoring & Automated Alerting with Bash Script
6. **Lab 6**: Git Internals, Disaster Recovery with Reflog & Git Hooks Automation
7. **Lab 7**: Advanced Git Branching, Complex Conflict Resolution & PR Workflows
8. **Lab 8**: PostgreSQL, Redis & Automated Database Migration with Flyway
9. **Lab 9**: Docker CLI Fundamentals, Image Layers & Interactive Containers
10. **Lab 10**: Runtime Resource Configuration, Log Management & Graceful Shutdown Testing

Chuỗi bài lab này trang bị đầy đủ kiến thức từ mạng máy tính, an toàn máy chủ, điều phối lưu lượng web, tự động hóa script, quản lý mã nguồn Git nâng cao, hạ tầng cơ sở dữ liệu và caching, cho đến quản trị Docker Runtime chuẩn DevOps hiện đại!

