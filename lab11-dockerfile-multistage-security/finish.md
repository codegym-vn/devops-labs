# Hoàn Thành Bài Thực Hành: Thiết Kế Dockerfile Multi-stage, Tối Ưu Cache & Phân Quyền Non-Root

Chúc mừng bạn đã hoàn thành xuất sắc **Lab 11: Thiết Kế Dockerfile Multi-stage, Tối Ưu Cache & Phân Quyền Non-Root**!

Bạn đã nâng tầm kỹ năng đóng gói ứng dụng từ mức nghiệp dư lên chuẩn **Enterprise Production**: hình ảnh ứng dụng không chỉ build nhanh, dung lượng siêu nhẹ mà còn đáp ứng các tiêu chuẩn an ninh nghiêm ngặt nhất của môi trường đám mây và Kubernetes.

---

## 1. Những Năng Lực Cốt Lõi Đã Đạt Được

- **Làm chủ Layer Caching**: Nắm vững nguyên lý băm nội dung của Docker BuildKit, biết cách cấu hình `.dockerignore` để bảo vệ Build Context, và sắp xếp thứ tự chỉ thị thông minh để tận dụng 100% cache khi mã nguồn ứng dụng thay đổi.
- **Thành thạo Multi-stage Build**: Tách bạch hoàn toàn môi trường biên dịch (Builder) chứa compiler/SDK cồng kềnh khỏi môi trường thực thi (Runtime). Giảm dung lượng image từ **> 300MB xuống chỉ còn ~15MB** (tiết kiệm hơn 95% dung lượng đĩa và băng thông mạng).
- **Siết chặt bảo mật với Non-Root User**: Thấu hiểu rủi ro của quyền `root (UID 0)` đối với nguy cơ Container Breakout. Triển khai chuẩn xác nguyên tắc **Least Privilege** với người dùng chuyên biệt (`USER 10001:10001`), sẵn sàng vượt qua các bài kiểm tra bảo mật khắt khe như CIS Docker Benchmark và Kubernetes Pod Security Standards.

---

## 2. Bảng Tra Cứu Quy Chuẩn Dockerfile Production (Cheat Sheet)

| Hạng Mục | Tiêu Chuẩn Kỹ Thuật | Cú Pháp Thực Hiện |
| :--- | :--- | :--- |
| **Build Context** | Loại trừ file rác, tệp tin bí mật | Khởi tạo `.dockerignore` chứa `.git`, `.env`, `*.md` |
| **Thứ tự Cache** | Dependency descriptor trước, source code sau | `COPY go.mod ./` -> `RUN go mod download` -> `COPY main.go ./` |
| **Biên dịch tĩnh** | Không phụ thuộc libc, tối ưu kích thước nhị phân | `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server` |
| **Multi-stage** | Tách builder và runtime | `FROM <builder> AS builder` ... `FROM <runtime>` ... `COPY --from=builder` |
| **Base Image** | Lựa chọn distro tối giản, ít lỗ hổng CVE | Sử dụng `alpine:3.19` hoặc `distroless/static-debian12` |
| **Phân quyền** | Chạy bằng UID non-root cố định | `RUN addgroup -g 10001 -S appgroup && adduser -u 10001 -S appuser -G appgroup` |
| **Sở hữu file** | Gán quyền cho non-root khi copy | `COPY --chown=10001:10001 --from=builder /app/server /app/server` |
| **Khai báo người dùng**| Sử dụng số thay vì tên chữ | `USER 10001:10001` |
| **Dạng lệnh thực thi** | Luôn dùng Exec Form để nhận tín hiệu OS | `CMD ["/app/server"]` (Tránh dùng Shell form: `CMD /app/server`) |

---

## 3. Checklist Tự Đánh Giá Năng Lực

- [x] Hiểu rõ hiện tượng Cache Busting và quy tắc vô hiệu hóa dây chuyền của Docker layers.
- [x] Khởi tạo và sử dụng thành thạo file `.dockerignore`.
- [x] Xây dựng thành công Dockerfile đa tầng sử dụng `FROM ... AS` và `COPY --from=`.
- [x] Áp dụng các cờ biên dịch tối ưu kích thước file thực thi (`CGO_ENABLED=0`, `-ldflags="-s -w"`).
- [x] Phân tích được các nguy cơ bảo mật khi chạy container bằng quyền root (UID 0).
- [x] Khởi tạo nhóm, người dùng non-root và phân quyền tập tin chính xác bằng `--chown`.
- [x] Kiểm chứng thành công quyền hạn tiến trình qua metadata image và lệnh `id -u`.

---

## Tổng Kết Chuỗi Bài Thực Hành DevOps & Networking Labs

Bạn đã hoàn thành trọn vẹn **11 bài thực hành chuyên sâu từ cơ bản đến nâng cao**:
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
11. **Lab 11**: Production Multi-stage Dockerfile, Cache Optimization & Non-Root Security Hardening
