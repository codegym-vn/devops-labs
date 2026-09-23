# Chúc Mừng Bạn Đã Hoàn Thành Lab 6!

Bạn đã hoàn thành xuất sắc bài thực hành chuyên sâu về **Git Internals, Khôi Phục Dữ Liệu Với Reflog & Cấu Hình Git Hooks**. Giờ đây, bạn đã làm chủ một trong những công cụ quan trọng nhất của kỹ sư phần mềm và DevOps từ tầng kiến trúc bên trong.

---

## Bảng Tra Cứu Nhanh Lệnh Git Nâng Cao (Advanced Git Cheat Sheet)

### 1. Git Plumbing Commands (Mổ Xẻ Đối Tượng)

| Lệnh | Ý Nghĩa | Ví Dụ |
|---|---|---|
| `git cat-file -t <SHA>` | Xem kiểu đối tượng (blob/tree/commit/tag) | `git cat-file -t HEAD` |
| `git cat-file -p <SHA>` | Xem nội dung giải nén của đối tượng | `git cat-file -p HEAD` |
| `git ls-tree <SHA>` | Xem danh sách file trong một tree | `git ls-tree HEAD:scripts` |
| `git rev-parse <ref>` | Lấy mã SHA-1 40 ký tự đầy đủ | `git rev-parse main` |
| `git hash-object -w <file>` | Tính mã SHA và lưu blob vào database | `git hash-object -w file.txt` |

### 2. Cứu Dữ Liệu & Khắc Phục Sự Cố (Disaster Recovery)

| Tình Huống | Lệnh Khắc Phục |
|---|---|
| **Lỡ tay reset mất commit** | `git reflog` rồi `git reset --hard HEAD@{n}` |
| **Xóa nhầm branch** | Tìm SHA cuối trên reflog, chạy `git branch <name> <SHA>` |
| **Quét đối tượng mồ côi** | `git fsck --lost-found` |
| **Xem chi tiết một reflog** | `git reflog show <tên_branch>` |

### 3. Git Hooks Vận Hành

| Hook | Thời Điểm Chạy | Ứng Dụng Thực Chiến |
|---|---|---|
| `pre-commit` | Trước khi commit | Quét Secret, Lint cú pháp, Unit Test nhanh |
| `commit-msg` | Sau khi nhập message | Ép chuẩn Conventional Commits |
| `pre-push` | Trước khi push lên remote | Chạy Integration Test, kiểm tra branch name |
| `post-commit` | Sau khi commit xong | Gửi notification, audit logging |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Hiểu rõ cấu trúc thư mục `.git/` (`objects`, `refs`, `HEAD`, `index`).
- [x] Phân biệt được 4 loại Git Objects: Blob, Tree, Commit và Tag.
- [x] Sử dụng thành thạo các Plumbing Commands (`cat-file`, `ls-tree`, `rev-parse`) để duyệt cây dữ liệu.
- [x] Nắm vững cơ chế bất biến (immutability) của Git và vòng đời của dangling objects.
- [x] Sử dụng thành thạo `git reflog` để giải cứu commit và branch bị xóa nhầm.
- [x] Hiểu vòng đời Client-side Git Hooks và cơ chế hủy thao tác khi trả về mã lỗi (`exit 1`).
- [x] Tự xây dựng được `pre-commit` hook ngăn chặn rò rỉ secret và `commit-msg` hook chuẩn hóa Conventional Commits.

---

## Tổng Kết Khóa Thực Hành DevOps & Networking Labs

Chúc mừng bạn đã hoàn thành trọn vẹn cả 6 bài thực hành trong hệ thống:
1. **Lab 1**: TCP/IP, Subnetting, Routing & DNS Troubleshooting
2. **Lab 2**: HTTP/HTTPS Protocols, TLS Handshake & Nginx SSL Configuration
3. **Lab 3**: SSH Hardening, Tunneling Port Forwarding & UFW Firewall
4. **Lab 4**: Nginx Reverse Proxy, Load Balancing Algorithms & Connection Pooling
5. **Lab 5**: Server Resource Monitoring & Automated Alerting with Bash Script
6. **Lab 6**: Git Internals, Disaster Recovery with Reflog & Git Hooks Automation

Bạn hiện đã sở hữu nền tảng kiến thức và kỹ năng thực chiến vững chắc về mạng máy tính, bảo mật hạ tầng, vận hành web server và tự động hóa công cụ trong môi trường DevOps!
