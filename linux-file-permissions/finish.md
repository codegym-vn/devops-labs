# Chúc Mừng Bạn Đã Hoàn Thành Bài Thực Hành!

Bạn đã xuất sắc làm chủ toàn bộ nền tảng bảo mật tệp tin và phân quyền trong Linux: **Giải mã 10 ký tự quyền hạn -> Thiết lập quyền với chmod (Symbolic & Octal) -> Quản trị quyền sở hữu User/Group với chown/chgrp**.

Đây là kỹ năng bảo mật cốt lõi giúp bạn tự tin làm việc với máy chủ Linux, viết Dockerfile an toàn (Non-root user) và triển khai ứng dụng trên Kubernetes mà không sợ các lỗ hổng phân quyền.

---

## Bảng Tra Cứu Phân Quyền Nhanh (Linux Permissions Cheat Sheet)

### 1. Bảng Giá Trị Quyền Số Bát Phân (Octal Values)

| Quyền | Ký Hiệu | Giá Trị Số | Ý Nghĩa Thực Tế |
|---|:---:|:---:|---|
| **Read** | `r` | **4** | Đọc nội dung file / Xem danh sách file trong thư mục |
| **Write** | `w` | **2** | Sửa file / Tạo, xóa, đổi tên file trong thư mục |
| **Execute** | `x` | **1** | Chạy chương trình / Bước chân (`cd`) vào thư mục |
| **None** | `-` | **0** | Không có bất kỳ quyền nào |

---

### 2. Các Mức Quyền Kinh Điển Trong Production

| Giá Trị | Ký Hiệu | Đối Tượng Sử Dụng Tiêu Biểu |
|:---:|:---:|---|
| **`755`** | `rwxr-xr-x` | Thư mục hệ thống, thư mục dự án, script triển khai (`.sh`) |
| **`644`** | `rw-r--r--` | File cấu hình (`.env`, `nginx.conf`), tài liệu, mã nguồn |
| **`600`** | `rw-------` | SSH Private Key (`id_rsa`, `id_ed25519`), file mật khẩu DB |
| **`400`** | `r--------` | Khóa bảo mật AWS EC2 (`.pem`), secret chỉ đọc |
| **`775`** | `rwxrwxr-x` | Thư mục chia sẻ cho nhóm (như thư mục `logs` cho team dev ghi log) |

---

### 3. Bảng Lệnh Quản Trị Sở Hữu (Ownership Commands)

| Lệnh Thực Hiện | Mục Đích |
|---|---|
| `chown user1 app.py` | Đổi chủ sở hữu file sang `user1` |
| `chown user1:devs app.py` | Đổi cả chủ sở hữu sang `user1` và nhóm sang `devs` |
| `chown -R user1:devs /app` | Đổi đệ quy cho cả thư mục và mọi tệp bên trong |
| `chgrp devs /app/logs` | Đổi nhóm sở hữu sang `devs` |
| `chmod +x deploy.sh` | Cấp nhanh quyền thực thi cho script |
| `chmod -R 755 /var/www` | Phân quyền đệ quy cho toàn bộ thư mục web |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Đọc và giải thích được ý nghĩa từng ký tự trong chuỗi 10 ký tự của `ls -l`.
- [x] Hiểu sự khác biệt giữa quyền `x` trên File (chạy script) và trên Thư mục (`cd` vào bên trong).
- [x] Thành thạo cách tính nhẩm giá trị bát phân (4 - 2 - 1).
- [x] Nhớ và áp dụng chính xác các mức quyền tiêu chuẩn: `755`, `644`, `600`, `400`.
- [x] Biết cách dùng `chown` và `chgrp` để gán quyền cho tài khoản dịch vụ phi đặc quyền (Non-root service user).
- [x] Luôn tuân thủ Nguyên tắc Đặc quyền Tối thiểu (Principle of Least Privilege).

---

## Lộ Trình Tiếp Theo

Sau khi đã nắm vững Terminal, điều hướng thư mục và phân quyền tệp tin, bạn đã sở hữu đầy đủ hành trang vững chắc để bước vào **Lab 1: TCP/IP và DNS Trong DevOps** để bắt đầu chinh phục thế giới mạng máy tính chuyên sâu!
