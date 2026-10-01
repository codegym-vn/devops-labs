# Chúc Mừng Bạn Đã Hoàn Thành Bài Thực Hành!

Bạn đã xuất sắc chinh phục các kỹ năng nền tảng quan trọng nhất của dòng lệnh Linux: **Hiểu Terminal Prompt & Nhận diện máy chủ -> Điều hướng cây thư mục FHS -> Quản trị tệp tin và kiến trúc dự án**.

Từ đây, bạn đã hoàn toàn tự tin thao tác trên bất kỳ máy chủ Linux nào mà không còn cảm giác bỡ ngỡ trước con trỏ màn hình đen!

---

## Bảng Tra Cứu Nhanh (DevOps Terminal Cheat Sheet)

| Nhóm Thao Tác | Lệnh Tiêu Biểu | Cú Pháp Ví Dụ | Ý Nghĩa Thực Chiến |
|---|---|---|---|
| **Thẩm tra hệ thống** | `whoami`, `id` | `whoami` / `id` | Xác định user đang đăng nhập và quyền hạn (UID 0 là root) |
| **Thẩm tra hệ thống** | `hostname` | `hostname` | Kiểm tra tên máy chủ để tránh thao tác nhầm trên Production |
| **Thẩm tra hệ thống** | `pwd` | `pwd` | In đường dẫn tuyệt đối của thư mục làm việc hiện tại |
| **Điều hướng** | `cd` | `cd /var/log` | Di chuyển đến thư mục chỉ định bằng đường dẫn tuyệt đối |
| **Điều hướng** | `cd ..` | `cd ..` / `cd ../..` | Lùi về thư mục cha cấp trên bằng đường dẫn tương đối |
| **Điều hướng** | `cd ~` | `cd ~` hoặc chỉ gõ `cd` | Nhảy nhanh về thư mục Home của người dùng hiện tại |
| **Điều hướng** | `cd -` | `cd -` | **Phím tắt vàng:** Chuyển đổi qua lại với thư mục vừa đứng trước đó |
| **Tạo thư mục** | `mkdir -p` | `mkdir -p app/{src,configs}` | Tạo cây thư mục đa cấp và kết hợp Brace Expansion |
| **Tạo tệp** | `touch` | `touch app.env` | Tạo tệp rỗng hoặc cập nhật timestamp kích hoạt build |
| **Sao chép** | `cp`, `cp -r` | `cp file1 file2`<br>`cp -r src backup/` | Sao chép file đơn hoặc sao chép cả thư mục đệ quy |
| **Di chuyển / Đổi tên**| `mv` | `mv file.txt /tmp/`<br>`mv old.txt new.txt` | Di chuyển tệp/thư mục hoặc đổi tên tệp |
| **Xóa dữ liệu** | `rm`, `rm -rf` | `rm file.txt`<br>`rm -rf dir/` | Xóa file hoặc xóa đệ quy thư mục (Cần cẩn trọng tối đa!) |
| **Trực quan hóa** | `tree` | `tree -L 2` | Vẽ sơ đồ cây thư mục trực quan theo số cấp quy định |

---

## 5 Phím Tắt Tăng Tốc Năng Suất (Productivity Shortcuts)

1. **`Tab` (Auto-completion):** Gõ 1-2 chữ cái đầu rồi bấm `Tab`. Shell sẽ tự động hoàn thiện tên file/thư mục/lệnh, giúp tránh lỗi gõ sai chính tả.
2. **`Ctrl + C` (Cancel / Terminate):** Hủy ngay lập tức lệnh đang chạy nếu bị treo hoặc gõ nhầm.
3. **`Ctrl + L` (Clear Screen):** Xóa sạch màn hình terminal cho gọn gàng (tương đương lệnh `clear`) mà không mất lịch sử.
4. **`Mũi tên Lên / Xuống` (↑ / ↓):** Duyệt lại các câu lệnh đã gõ trước đó trong lịch sử.
5. **`Ctrl + R` (Reverse Search):** Tìm kiếm thông minh câu lệnh cũ trong lịch sử bash bằng từ khóa.

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Phân biệt được dấu nhắc lệnh `$` (user thông thường) và `#` (root superuser).
- [x] Đọc và hiểu được cấu trúc câu lệnh Linux gồm Command + Options + Arguments.
- [x] Biết cách kiểm tra định danh máy chủ (`whoami`, `hostname`, `id`, `pwd`).
- [x] Hiểu rõ bản đồ cây thư mục Linux FHS (`/`, `/etc`, `/var/log`, `/tmp`, `/home`).
- [x] Phân biệt và ứng dụng thành thạo Đường dẫn Tuyệt đối (`/`) và Tương đối (`.`, `..`).
- [x] Tận dụng lệnh `cd -` để chuyển đổi nhanh giữa hai thư mục làm việc.
- [x] Sử dụng thành thạo `mkdir -p` để tạo cấu trúc dự án phức tạp trong một lệnh.
- [x] Nắm vững các lệnh quản trị tệp `touch`, `cp -r`, `mv`, `rm -rf`, `tree`.
- [x] Hiểu rõ mối nguy hiểm của lệnh `rm -rf` trong môi trường tự động hóa DevOps.

---

## Bước Tiếp Theo Trong Lộ Trình

Bây giờ bạn đã hoàn toàn làm chủ Terminal và kỹ năng điều hướng thư mục, bạn đã sẵn sàng bước vào bài thực hành tiếp theo: **Lab 1: TCP/IP và DNS Trong DevOps** để khám phá thế giới mạng máy tính, tính toán Subnetting/CIDR, phân tích kết nối mạng và gỡ lỗi DNS chuyên sâu!
