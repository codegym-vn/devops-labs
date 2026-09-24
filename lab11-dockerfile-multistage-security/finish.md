# Hoàn Thành: Thiết Kế Dockerfile Multi-stage, Tối Ưu Cache & Phân Quyền Non-Root

Chúc mừng bạn đã hoàn thành **Lab 11**! Bạn đã nâng tầm kỹ năng đóng gói ứng dụng từ mức cơ bản lên chuẩn **Enterprise Production**: image build nhanh, dung lượng siêu nhẹ và đáp ứng các tiêu chuẩn an ninh nghiêm ngặt nhất.

---

## Năng Lực Đã Đạt Được

- **Layer Caching**: Nắm vững nguyên lý băm nội dung của Docker BuildKit, cấu hình `.dockerignore`, sắp xếp thứ tự chỉ thị để tận dụng 100% cache.
- **Multi-stage Build**: Tách biệt hoàn toàn Builder và Runtime. Giảm dung lượng image từ hơn 300MB xuống chỉ còn khoảng 15MB (tiết kiệm hơn 95%).
- **Non-Root Security**: Triển khai chuẩn xác nguyên tắc Least Privilege với `USER 10001:10001`, đáp ứng CIS Docker Benchmark và Kubernetes Pod Security Standards.

---

## Bảng Tra Cứu Quy Chuẩn Dockerfile Production

| Hạng Mục | Tiêu Chuẩn | Cú Pháp |
| :--- | :--- | :--- |
| **Build Context** | Loại trừ file rác, tệp bí mật | `.dockerignore` chứa `.git`, `.env`, `*.md` |
| **Thứ tự Cache** | Dependency trước, source code sau | `COPY go.mod` -> `go mod download` -> `COPY main.go` |
| **Biên dịch tĩnh** | Không phụ thuộc libc | `CGO_ENABLED=0 go build -ldflags="-s -w"` |
| **Multi-stage** | Tách builder và runtime | `FROM ... AS builder` -> `COPY --from=builder` |
| **Base Image** | Distro tối giản | `alpine:3.19` hoặc `distroless/static-debian12` |
| **Phân quyền** | UID non-root cố định | `addgroup -g 10001` + `adduser -u 10001` |
| **Sở hữu file** | Gán quyền khi copy | `COPY --chown=10001:10001 --from=builder` |
| **Khai báo user** | Dùng số thay vì tên chữ | `USER 10001:10001` |
| **Lệnh thực thi** | Exec Form để nhận tín hiệu OS | `CMD ["/app/server"]` |

---

## Checklist Tự Đánh Giá

- [x] Hiểu hiện tượng Cache Busting và quy tắc vô hiệu hóa dây chuyền
- [x] Sử dụng thành thạo `.dockerignore`
- [x] Xây dựng Dockerfile đa tầng với `FROM ... AS` và `COPY --from=`
- [x] Áp dụng cờ biên dịch tối ưu (`CGO_ENABLED=0`, `-ldflags="-s -w"`)
- [x] Phân tích nguy cơ bảo mật khi chạy container bằng root (UID 0)
- [x] Tạo người dùng non-root và phân quyền file bằng `--chown`
- [x] Kiểm chứng quyền hạn tiến trình qua API và lệnh `id`

---

## Tổng Kết Chuỗi Bài Thực Hành DevOps & Networking Labs

Bạn đã hoàn thành trọn vẹn **11 bài thực hành từ cơ bản đến nâng cao**:

1. **Lab 1**: TCP/IP, Subnetting, Routing & DNS Troubleshooting
2. **Lab 2**: HTTP/HTTPS Protocols, TLS Handshake & Nginx SSL Configuration
3. **Lab 3**: SSH Hardening, Tunneling Port Forwarding & UFW Firewall
4. **Lab 4**: Nginx Reverse Proxy, Load Balancing Algorithms & Connection Pooling
5. **Lab 5**: Server Resource Monitoring & Automated Alerting with Bash Script
6. **Lab 6**: Git Internals, Disaster Recovery with Reflog & Git Hooks Automation
7. **Lab 7**: Advanced Git Branching, Complex Conflict Resolution & PR Workflows
8. **Lab 8**: PostgreSQL, Redis Cache-Aside & Flyway Database Migration
9. **Lab 9**: Docker CLI Fundamentals, Image Layers & Interactive Containers
10. **Lab 10**: Runtime Resource Configuration, Log Management & Graceful Shutdown
11. **Lab 11**: Production Dockerfile, Cache Optimization & Non-Root Security
