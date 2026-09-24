# Hoàn Thành Bài Thực Hành: Nhập Môn Docker CLI & Quản Lý Image Layers

Chúc mừng bạn đã hoàn thành xuất sắc **Lab 9: Nhập Môn Docker CLI, Cấu Trúc Image Layers & Tương Tác Container**!

---

## 1. Những Năng Lực Đã Đạt Được

Sau bài lab này, bạn đã làm chủ các kỹ năng cốt lõi:
- **Hiểu sâu cấu trúc Image Layers**: Nắm rõ cơ chế phân tầng (Layers), mã băm SHA256 (digest), cách Docker tái sử dụng cache khi tải image và cách gắn tag đa phiên bản.
- **Tương tác container linh hoạt**: Phân biệt rành mạch giữa `docker run -it` (khởi tạo môi trường mới) và `docker exec -it` (thâm nhập phiên làm việc trong container đang chạy).
- **Quản lý dữ liệu trực tiếp**: Sử dụng thành thạo `docker cp` để nạp và trích xuất file cấu hình/dữ liệu và `docker diff` để đối soát các file bị sửa đổi (`C`), tạo mới (`A`) hoặc xóa bỏ (`D`).
- **Làm chủ cơ chế Copy-on-Write (CoW)**: Hiểu cách storage driver `overlay2` bảo vệ tính bất biến của base image và lưu snapshot khẩn cấp bằng `docker commit`.

---

## 2. Bảng Tra Cứu Lệnh Docker CLI Cốt Lõi (Cheat Sheet)

| Mục Đích | Lệnh CLI Chuẩn | Ghi Chú Kỹ Thuật |
| :--- | :--- | :--- |
| Tải image từ Registry | `docker pull <image>:<tag>` | Tự động tải các layer chưa có trong local cache |
| Kiểm tra lịch sử layer | `docker history <image>` | Xem chi tiết kích thước và câu lệnh tạo từng layer |
| Gắn tag phiên bản | `docker tag <source> <target>` | Tạo alias tham chiếu cùng image ID |
| Chạy shell tương tác | `docker run -it --rm <image> sh` | Cấp phát TTY, giữ STDIN và tự dọn dẹp khi exit |
| Chạy container chạy ngầm | `docker run -d --name <name> -p <host>:<ctr> <image>` | Daemon mode, ánh xạ cổng mạng |
| Mở shell vào container đang chạy | `docker exec -it <name> sh` | Khởi tạo tiến trình phụ không làm gián đoạn tiến trình PID 1 |
| Sao chép file 2 chiều | `docker cp <src> <dest>` | Hoạt động giữa host và container mà không cần SSH |
| Đối soát thay đổi file | `docker diff <name>` | Xem danh sách file Added (A), Changed (C), Deleted (D) |
| Đóng gói container thành image | `docker commit -m "msg" -a "author" <name> <new_image>` | Tạo snapshot image từ Read-Write layer |

---

## 3. Bước Tiếp Theo

Ở bài lab tiếp theo, chúng ta sẽ bước lên cấp độ vận hành nâng cao: kiểm soát tài nguyên CPU/RAM, ngăn ngừa hiện tượng OOM (Out Of Memory) Killer, thiết lập cơ chế xoay vòng nhật ký (log rotation) để bảo vệ ổ cứng và kiểm thử quá trình dừng dịch vụ an toàn (Graceful Shutdown).

Khám phá ngay bài học tiếp theo:
**[Lab 10: Cấu Hình Tài Nguyên Runtime, Quản Lý Log Container & Graceful Shutdown](/lab10-runtime-logs-graceful-shutdown)**
