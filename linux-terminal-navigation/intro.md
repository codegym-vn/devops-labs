# Làm Quen Terminal & Điều Hướng Thư Mục Linux

Chào mừng bạn đến với bài thực hành nền tảng: **Làm Quen Terminal & Điều Hướng Thư Mục Linux**.

Trong văn hóa vận hành hệ thống hiện đại (**DevOps, SRE, Cloud Infrastructure và Containerization**), **Terminal** là cổng giao tiếp mặc định và mạnh mẽ nhất giữa bạn và máy chủ. Khi quản lý hàng trăm máy ảo trên AWS/GCP, điều hành cụm Kubernetes hay debug bên trong Docker Container, bạn sẽ không có giao diện đồ họa (GUI) — dòng lệnh (CLI) chính là công cụ sống còn duy nhất.

---

## 1. Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Làm chủ cấu trúc Terminal & Shell:** Hiểu rõ mối liên hệ giữa Terminal, Shell (Bash) và Linux Kernel; phân tích từng thành phần của chuỗi Prompt (`user@hostname:path$`).
2. **Nắm vững cú pháp lệnh Linux tiêu chuẩn:** Thành thạo quy tắc `command [options] [arguments]`, phân biệt cờ ngắn, cờ dài và cách gộp cờ.
3. **Thẩm tra định danh hệ thống tức thì:** Sử dụng thuần thục các lệnh `whoami`, `hostname`, `id`, `date`, `uname -a` và `pwd` kết hợp khai thác các biến môi trường cơ bản (`$USER`, `$HOME`, `$PWD`).
4. **Làm chủ điều hướng cây thư mục:** Hiểu cấu trúc phân cấp FHS (Filesystem Hierarchy Standard: `/`, `/home`, `/var`, `/etc`, `/tmp`), phân biệt đường dẫn Tuyệt đối vs Tương đối, làm chủ các ký hiệu đại diện (`.`, `..`, `~`, `-`).
5. **Thành thạo quản trị tệp tin & cấu trúc dự án:** Tạo nhanh cây thư mục đa cấp với `mkdir -p`, tạo file rỗng với `touch`, sao chép đệ quy với `cp -r`, di chuyển/đổi tên với `mv`, xóa an toàn với `rm -rf` và trực quan hóa cấu trúc dự án với `tree`.

---

## 2. Kiến Trúc Tương Tác: Terminal vs Shell vs Kernel

```
+-------------------------------------------------------------+
|                Người Dùng / DevOps Engineer                 |
+-------------------------------------------------------------+
                              |
                              v  (Gõ phím & hiển thị chữ)
+-------------------------------------------------------------+
|                    TERMINAL (Trình Giả Lập)                 |
|             (Ví dụ: GNOME Terminal, iTerm2, Kitty)          |
+-------------------------------------------------------------+
                              |
                              v  (Thông dịch câu lệnh)
+-------------------------------------------------------------+
|                       SHELL (Trình Vỏ)                      |
|                  (Bash, Zsh, Sh - chạy ngầm)                |
+-------------------------------------------------------------+
                              |
                              v  (Lời gọi hệ thống - System Calls)
+-------------------------------------------------------------+
|                     LINUX KERNEL (Nhân)                     |
|            (Quản lý CPU, RAM, Ổ cứng, Tiến trình)            |
+-------------------------------------------------------------+
```

---

## 3. So Sánh GUI vs CLI Trong Môi Trường Production

| Tiêu Chí So Sánh | Giao Diện Đồ Họa (GUI) | Dòng Lệnh Terminal (CLI) | Giá Trị Trong DevOps |
|---|---|---|---|
| **Tài nguyên tiêu tốn** | Tốn nhiều CPU, RAM để render đồ họa | Cực kỳ nhẹ, tối ưu tài nguyên tối đa | Tiết kiệm chi phí trên máy chủ Cloud |
| **Khả năng tự động hóa**| Khó tự động hóa, phụ thuộc tọa độ click | Tích hợp hoàn hảo vào Bash Script, CI/CD | Chạy tự động không cần con người can thiệp |
| **Quản trị từ xa (Remote)** | Cần đường truyền mạng băng thông lớn | Chỉ cần kết nối SSH nhẹ vài KB/s | Quản trị máy chủ ở bất kỳ đâu mượt mà |
| **Truy cập Container** | Gần như không thể chạy GUI trong container | `docker exec -it <id> sh` cực kỳ nhanh gọn | Debug container tức thì tại Production |

---

## 4. Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường (Background Initialization):** Hệ thống ngầm cài đặt sẵn các tiện ích bổ trợ như `tree`, `curl` và thiết lập không gian thực hành chuẩn hóa.
- **Thực thi lệnh một chạm:** Nhấn trực tiếp vào các khối lệnh code trên bảng hướng dẫn để tự động gửi lệnh vào terminal bên phải mà không cần copy/paste.
- **Tự động chấm điểm (Automated Verification):** Mỗi bước đều có phần **Thử Thách (Challenge)**. Sau khi hoàn thành xong yêu cầu, bạn chỉ cần bấm nút **Check** ở góc thanh điều khiển để hệ thống tự động kiểm tra và chuyển bước.

Bấm **START** hoặc chọn **Bước 1** ở thanh điều hướng để bắt đầu hành trình làm chủ dòng lệnh Linux!
