# Chúc Mừng Bạn Đã Hoàn Thành Lab 7!

Bạn đã làm chủ toàn diện các kỹ năng cộng tác nâng cao trong Git: từ quản lý chiến lược phân nhánh, giải quyết xung đột đa file phức tạp bằng **3-Way Merge & zdiff3**, cho đến việc làm chủ kỹ thuật **Rebase** và quy trình **Pull Request & Squash Merge** chuẩn công nghiệp.

---

## Bảng Tra Cứu Nhanh Lệnh Git Cộng Tác & Xử Lý Xung Đột (Git Collaboration Cheat Sheet)

### 1. Phân Nhánh & Quản Lý Remote

| Mục Đích | Lệnh Thực Hiện | Giải Thích |
|---|---|---|
| **Xem remote repo** | `git remote -v` | Xem danh sách URL các remote server |
| **Xem tất cả nhánh** | `git branch -a` | Liệt kê cả local và remote tracking branches |
| **Cập nhật con trỏ remote** | `git fetch origin` | Tải commit mới từ server mà không merge |
| **Tạo & chuyển nhánh** | `git checkout -b <branch>` | Tạo branch mới từ commit hiện tại |
| **Push & theo dõi** | `git push -u origin <branch>` | Đẩy nhánh lên server và gắn upstream |

### 2. Giải Quyết Xung Đột Hợp Nhất (Conflict Resolution)

| Mục Đích | Lệnh Thực Hiện | Giải Thích |
|---|---|---|
| **Bật chế độ zdiff3** | `git config --global merge.conflictstyle zdiff3` | Hiển thị thêm khối `base` gốc ban đầu |
| **Xem file bị xung đột** | `git status` | Tìm các file có trạng thái `both modified` |
| **Đánh dấu đã sửa** | `git add <file>` | Thông báo cho Git file đã được giải quyết |
| **Hoàn tất merge** | `git commit -m "<message>"` | Tạo merge commit kết thúc xung đột |
| **Hủy bỏ merge an toàn** | `git merge --abort` | Quay về trạng thái sạch sẽ trước khi merge |

### 3. Rebase & Pull Request Workflows

| Mục Đích | Lệnh Thực Hiện | Giải Thích |
|---|---|---|
| **Xem commit của PR** | `git log main..<branch> --oneline` | Danh sách commit riêng của nhánh tính năng |
| **Xem thay đổi của PR** | `git diff main...<branch>` | So sánh từ Merge Base tới đỉnh nhánh |
| **Rebase lên main** | `git rebase main` | Tua lại và đặt commit lên đỉnh của `main` |
| **Tiếp tục rebase** | `git rebase --continue` | Sau khi đã `git add` file giải quyết xung đột |
| **Hủy bỏ rebase** | `git rebase --abort` | Hủy toàn bộ tiến trình rebase đang dang dở |
| **Squash & Merge** | `git merge --squash <branch>` | Gom tất cả commit thành 1 thay đổi duy nhất |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Phân biệt được Local Branch, Remote Tracking Branch và Remote Central Server.
- [x] Áp dụng được chiến lược phân nhánh Trunk-Based Development trong dự án thực tế.
- [x] Thành thạo kỹ thuật review Pull Request trên dòng lệnh bằng cú pháp `git diff main...feature`.
- [x] Hiểu bản chất 3-Way Merge và cấu hình hiển thị nâng cao `zdiff3`.
- [x] Tự tin giải quyết xung đột đa file phức tạp mà không làm mất mã nguồn của đồng nghiệp.
- [x] Hiểu rõ sự khác biệt giữa `git merge` và `git rebase` cũng như Quy Tắc Vàng của Rebase.
- [x] Xử lý xung đột từng bước trong tiến trình Rebase bằng `git rebase --continue`.
- [x] Thực hiện thành thạo kỹ thuật Squash & Merge để giữ lịch sử dự án luôn sạch sẽ.

---

## Bước Tiếp Theo

Tiếp tục hành trình làm chủ hạ tầng ứng dụng và cơ sở dữ liệu với bài thực hành tiếp theo:
- **Lab 8**: [Triển khai kết nối PostgreSQL, Redis và chạy Flyway Migration](/lab8-postgres-redis-flyway)

---

## Tổng Kết Chuỗi Bài Thực Hành DevOps & Networking Labs

Bạn đã hoàn thành 7 chặng đường quan trọng và đang tiến tới các bài thực hành về cơ sở dữ liệu và lưu trữ đệm:
1. **Lab 1**: TCP/IP, Subnetting, Routing & DNS Troubleshooting
2. **Lab 2**: HTTP/HTTPS Protocols, TLS Handshake & Nginx SSL Configuration
3. **Lab 3**: SSH Hardening, Tunneling Port Forwarding & UFW Firewall
4. **Lab 4**: Nginx Reverse Proxy, Load Balancing Algorithms & Connection Pooling
5. **Lab 5**: Server Resource Monitoring & Automated Alerting with Bash Script
6. **Lab 6**: Git Internals, Disaster Recovery with Reflog & Git Hooks Automation
7. **Lab 7**: Advanced Git Branching, Complex Conflict Resolution & PR Workflows
8. **Lab 8**: Triển khai kết nối PostgreSQL, Redis và chạy Flyway Migration

Bộ kỹ năng này tạo nên nền tảng vững chắc cho bất kỳ kỹ sư DevOps, SRE, hay Cloud Engineer nào trên con đường phát triển sự nghiệp chuyên nghiệp!

