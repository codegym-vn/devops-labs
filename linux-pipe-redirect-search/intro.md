# Pipe, Redirect & Tìm Kiếm Trong Linux

Chào mừng bạn đến với bài thực hành: **Pipe, Redirect & Tìm Kiếm Trong Linux**.

Một trong những sức mạnh vĩ đại nhất giúp Linux thống trị toàn bộ thế giới điện toán đám mây và máy chủ là **Triết lý Unix (Unix Philosophy)**:
> *"Viết những chương trình chỉ làm một việc duy nhất nhưng làm thật xuất sắc. Viết những chương trình có khả năng kết hợp chặt chẽ với nhau. Viết những chương trình xử lý các luồng văn bản, bởi vì văn bản là giao diện phổ quát nhất."*

Khi viết Bash Script tự động hóa, cấu hình Cronjob, xử lý log trong Kubernetes hay xây dựng CI/CD Pipeline, bạn sẽ liên tục:
- Tách bạch luồng thông báo bình thường và luồng lỗi để gửi cảnh báo tự động.
- Nối các lệnh đơn lẻ lại thành một dây chuyền xử lý dữ liệu phức tạp chỉ bằng một đường ống duy nhất (`|`).
- Quét tìm nhanh các tệp cấu hình bí mật hoặc lỗ hổng lộ lọt token trong hàng chục nghìn file mã nguồn với `find` và `grep`.

---

## 1. Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Làm chủ 3 luồng dữ liệu chuẩn:** Hiểu sâu sắc cơ chế hoạt động của `stdin` (0), `stdout` (1) và `stderr` (2).
2. **Thành thạo kỹ thuật chuyển hướng (Redirection):** Sử dụng chuẩn xác các toán tử `>`, `>>`, `2>`, `2>&1` và hố đen `/dev/null` để lọc sạch thông báo hoặc lưu trữ nhật ký theo ý muốn.
3. **Làm chủ cơ chế đường ống (Pipes):** Ghép nối các lệnh độc lập thành dây chuyền chế biến dữ liệu mạnh mẽ bằng toán tử `|` kết hợp `grep`, `wc`, `sort`, `uniq` và ngã ba đường ống `tee`.
4. **Tìm kiếm tệp tin & nội dung chuyên sâu:** Quét tìm tệp theo tên, loại và thời gian bằng `find`, đồng thời truy vết các chuỗi ký tự bí mật đệ quy trong thư mục dự án bằng `grep -rn`.

---

## 2. Kiến Trúc 3 Luồng Dữ Liệu & Đường Ống

```
                      +-------------------+
                      |   LỆNH LINUX 1    |
                      +-------------------+
                     /         |           \
     (stdin: 0)     /          |            \  (stderr: 2)
  Dữ liệu đầu vào  /   (stdout: 1)           \  Thông báo lỗi
                  v            v              v
            [Bàn phím/File]    |          [error.log / Màn hình]
                               |
                               v  Đường ống Pipe (|)
                      +-------------------+
                      |   LỆNH LINUX 2    |
                      +-------------------+
                               |
                               v  (stdout: 1)
                      [Kết quả cuối cùng / File đích]
```

---

## 3. Tính Năng Tương Tác Trên Killercoda

- **Môi trường tự động hóa:** Các kịch bản chẩn đoán giả lập, tệp bản ghi máy chủ web Nginx và cấu trúc microservices phức tạp đã được tạo sẵn ngầm trong hệ thống.
- **Thực thi nhanh một chạm:** Nhấn trực tiếp vào các khối code hướng dẫn để tự động gửi lệnh vào terminal bên phải.
- **Tự động chấm điểm (Automated Verification):** Mỗi bước đều có phần Thử Thách và script kiểm tra thông minh để đánh giá kết quả thực hành của bạn.

Bấm **START** hoặc chọn **Bước 1** ở thanh điều hướng để bắt đầu!
