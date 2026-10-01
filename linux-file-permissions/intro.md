# Thao Tác Tệp & Phân Quyền Trong Linux

Chào mừng bạn đến với bài thực hành: **Thao Tác Tệp & Phân Quyền Trong Linux**.

Trong quản trị hệ thống và vận hành hạ tầng đám mây (**DevOps, Cloud Security, SRE**), **Bảo mật và Phân quyền (Linux Permissions)** là tấm lá chắn đầu tiên bảo vệ máy chủ khỏi nguy cơ bị xâm nhập, rò rỉ dữ liệu hoặc phá hoại ngoài ý muốn. 

Hầu như mọi sự cố an ninh nghiêm trọng hoặc lỗi triển khai trong DevOps đều liên quan đến phân quyền:
- Lỗi khóa bảo mật SSH: OpenSSH từ chối kết nối nếu file `id_rsa` bị gán quyền quá lỏng lẻo (`Permissions are too open`).
- Rủi ro bị tấn công Deface Web: Gán nhầm quyền ghi (`write`) cho toàn bộ Internet vào thư mục web server.
- Vi phạm nguyên tắc bảo mật Container: Chạy ứng dụng dưới quyền `root` trong container thay vì tạo user dịch vụ riêng biệt.

---

## 1. Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Làm chủ cấu trúc 10 ký tự quyền hạn:** Đọc hiểu chi tiết kết quả lệnh `ls -l`, phân biệt loại file/thư mục và 3 nhóm đối tượng truy cập (User, Group, Others).
2. **Hiểu sâu sắc ý nghĩa của bộ quyền `rwx`:** Phân biệt sự khác nhau mang tính cốt lõi của quyền Đọc (`r`), Ghi (`w`) và Thực thi (`x`) khi áp dụng lên **File** so với khi áp dụng lên **Thư mục**.
3. **Thành thạo công cụ `chmod`:** Làm chủ 2 phương pháp phân quyền kinh điển gồm Dạng ký hiệu (`+x`, `u=rw,go=r`) và Dạng số bát phân Octal (`755`, `644`, `600`, `400`).
4. **Quản trị sở hữu với `chown` và `chgrp`:** Thiết lập quyền sở hữu người dùng và nhóm dịch vụ theo **Nguyên tắc Đặc quyền Tối thiểu (Principle of Least Privilege)** chuẩn Production.

---

## 2. Mô Hình Phân Quyền 3 Nhóm Đối Tượng Trong Linux

Mọi đối tượng trên hệ thống tệp Linux đều gắn liền với 3 nhóm phân quyền độc lập:

```
+-------------------------------------------------------------------------+
|                  CẤU TRÚC 10 KÝ TỰ PHÂN QUYỀN (ls -l)                   |
+-------------------------------------------------------------------------+
|  [ - ]    |    [ r w x ]    |       [ r - x ]       |      [ r - - ]    |
|-----------|-----------------|-----------------------|-------------------|
| Loại tệp  |  User (Chủ sở   |  Group (Nhóm người    |  Others (Mọi      |
| (-: file, |  hữu tạo tệp)   |  dùng cùng nhóm)      |  người còn lại)   |
| d: dir)   |                 |                       |                   |
+-------------------------------------------------------------------------+
```

---

## 3. Nguyên Tắc Đặc Quyền Tối Thiểu (Principle of Least Privilege)

> **Quy Tắc Vàng:** Không bao giờ cấp quyền nhiều hơn mức cần thiết để thực hiện công việc!
> - Một file cấu hình chỉ nên cho phép **đọc**, không được cấp quyền thực thi (`x`).
> - Một thư mục web tĩnh chỉ nên cho phép đọc đối với người ngoài, tuyệt đối không cấp quyền ghi (`w`).
> - Khóa bí mật (Private Key, API Secret) chỉ duy nhất chủ sở hữu được phép đọc, chặn hoàn toàn Group và Others.

---

## 4. Tính Năng Tương Tác Trên Killercoda

- **Khởi tạo môi trường tự động (Background Automation):** Các tệp tin mẫu, thư mục bảo mật và tài khoản dịch vụ giả lập đã được tạo ngầm trong hệ thống.
- **Thực thi lệnh nhanh:** Bấm chuột trực tiếp vào khối lệnh code để gửi lệnh thực thi sang terminal bên phải mà không cần sao chép thủ công.
- **Chấm điểm tự động (Verification Check):** Mỗi bước đều đi kèm một phần **Thử Thách**. Sau khi thao tác xong, bạn chỉ cần bấm nút **Check** để hệ thống kiểm tra và xác thực kết quả.

Bấm **START** hoặc chọn **Bước 1** ở thanh điều hướng để bắt đầu!
