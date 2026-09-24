# Chúc Mừng Bạn Đã Hoàn Thành Lab 10!

Bạn đã làm chủ toàn diện các kỹ năng vận hành và quản trị nâng cao của **Docker Runtime**: từ quản lý vòng đời container, kiểm soát giới hạn tài nguyên CPU/RAM, cơ chế bảo vệ máy chủ bằng Log Rotation, cho đến kỹ thuật xử lý tín hiệu hệ điều hành và kiểm thử **Graceful Shutdown** chuẩn Production.

---

## Bảng Tra Cứu Nhanh Lệnh Quản Trị Runtime & Logging (Docker Ops Cheat Sheet)

### 1. Tham Số Runtime & Vòng Đời Container

| Mục Đích | Lệnh Thực Hiện | Giải Thích Chi Tiết |
|---|---|---|
| **Nạp file biến môi trường** | `docker run --env-file .env <image>` | Nạp hàng loạt cấu hình tách biệt mã nguồn |
| **Ánh xạ cổng mạng** | `docker run -p 8080:80 <image>` | Mở cổng host 8080 trỏ vào cổng container 80 |
| **Chính sách tự phục hồi** | `docker run --restart unless-stopped <image>` | Tự khởi động lại khi crash hoặc khi daemon restart |
| **Theo dõi tài nguyên** | `docker stats --no-stream` | Báo cáo tức thì mức % CPU, RAM, Network I/O |
| **Tạm dừng tiến trình** | `docker pause / unpause <name>` | Đóng băng hoặc mở lại container bằng cgroups freezer |

### 2. Giới Hạn Tài Nguyên & Quản Trị Log

| Mục Đích | Lệnh Thực Hiện | Giải Thích Chi Tiết |
|---|---|---|
| **Giới hạn CPU** | `docker run --cpus 0.5 <image>` | Giới hạn tối đa 50% của 1 nhân CPU |
| **Giới hạn RAM vật lý** | `docker run --memory 256m <image>` | Ngưỡng bộ nhớ tối đa trước khi bị OOM Killer |
| **Chặn bộ nhớ Swap** | `docker run --memory 256m --memory-swap 256m` | Vô hiệu hóa swap để ngăn sụt giảm hiệu năng đĩa |
| **Cấu hình Log Rotation** | `--log-opt max-size=2m --log-opt max-file=3` | Giới hạn dung lượng file log để bảo vệ ổ đĩa máy chủ |
| **Lọc log dạng JSON** | `docker logs <name> \| jq .` | Bóc tách log có cấu trúc để phân tích sự cố |

### 3. Tín Hiệu UNIX & Graceful Shutdown

| Mục Đích | Lệnh Thực Hiện | Giải Thích Chi Tiết |
|---|---|---|
| **Dừng êm đềm có thời hạn** | `docker stop -t 10 <name>` | Gửi `SIGTERM (15)` và đợi tối đa 10s trước khi dùng `SIGKILL (9)` |
| **Ép tắt tức thì** | `docker kill <name>` | Gửi trực tiếp `SIGKILL (9)` (nguy cơ hỏng dữ liệu) |
| **Kiểm tra mã thoát** | `docker inspect -f '{{.State.ExitCode}}'` | `0`: Tắt an toàn; `137`: Bị OOM hoặc SIGKILL |
| **Kiểm tra OOM Killer** | `docker inspect -f '{{.State.OOMKilled}}'` | Trả về `true` nếu bị Linux kernel tiêu diệt do tràn RAM |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Phân biệt rõ các trạng thái trong vòng đời container: Created, Running, Paused, Stopped, Destroyed.
- [x] Áp dụng thành thạo biến môi trường (`--env-file`) và chính sách phục hồi (`--restart unless-stopped`).
- [x] Hiểu bản chất cơ chế cgroups trên Linux kernel và cấu hình chuẩn `--cpus`, `--memory`, `--memory-swap`.
- [x] Nhận diện nguyên nhân và dấu hiệu của hiện tượng OOM Killer (Exit code 137, OOMKilled: true).
- [x] Thiết lập chính sách xoay vòng log (Log Rotation) để triệt tiêu nguy cơ đầy 100% dung lượng đĩa máy chủ.
- [x] Bóc tách cạm bẫy tiến trình PID 1 trong container (Shell form vs Exec form).
- [x] Xây dựng và kiểm thử thành công quy trình Graceful Shutdown bảo toàn giao dịch người dùng (Connection Draining).

---

## Tổng Kết Chuỗi Bài Thực Hành DevOps & Networking Labs

Bạn đã hoàn thành trọn vẹn **10 bài thực hành nền tảng và nâng cao**:
1. **Lab 1**: TCP/IP, Subnetting, Routing & DNS Troubleshooting
2. **Lab 2**: HTTP/HTTPS Protocols, TLS Handshake & Nginx SSL Configuration
3. **Lab 3**: SSH Hardening, Tunneling Port Forwarding & UFW Firewall
4. **Lab 4**: Nginx Reverse Proxy, Load Balancing Algorithms & Connection Pooling
5. **Lab 5**: Server Resource Monitoring & Automated Alerting with Bash Script
6. **Lab 6**: Git Internals, Disaster Recovery with Reflog & Git Hooks Automation
7. **Lab 7**: Advanced Git Branching, Complex Conflict Resolution & PR Workflows
8. **Lab 8**: PostgreSQL, Redis Cache-Aside & Flyway Database Migration
9. **Lab 9**: Docker CLI Fundamentals, Image Layers & Interactive Containers
10. **Lab 10**: Runtime Resource Configuration, Log Management & Graceful Shutdown Testing

