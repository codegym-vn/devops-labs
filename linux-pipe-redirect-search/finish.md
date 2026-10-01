# Chúc Mừng Bạn Đã Hoàn Thành Bài Thực Hành!

Bạn đã xuất sắc làm chủ 3 kỹ năng tự động hóa và xử lý dữ liệu mạnh mẽ bậc nhất của Linux:
1. **Quản trị 3 luồng dữ liệu chuẩn (stdin, stdout, stderr)** và nghệ thuật chuyển hướng dữ liệu với >, >>, 2>, 2>&1, /dev/null.
2. **Xây dựng chuỗi đường ống Pipe (|)** kết hợp các bộ lọc văn bản grep, wc, sort, uniq và ngã ba đường ống tee.
3. **Tìm kiếm tệp và nội dung chuyên sâu** với bộ đôi công cụ quyền lực find (quét theo thuộc tính tệp) và grep -rn (truy vết nội dung đệ quy).

---

## Bảng Tra Cứu Nhanh (Pipes, Redirect & Search Cheat Sheet)

### 1. Bảng Toán Tử Chuyển Hướng (Redirection)

| Cú Pháp | Kênh Tác Động | Hành Động Thực Tế |
|---|:---:|---|
| `command > file` | `stdout` (1) | Ghi đè kết quả thành công vào file |
| `command >> file` | `stdout` (1) | Ghi nối tiếp kết quả vào cuối file |
| `command 2> file` | `stderr` (2) | Chuyển riêng thông báo lỗi ra file |
| `command > file 2>&1` | Cả `1` và `2` | Hợp nhất cả kết quả và lỗi vào cùng 1 file |
| `command &> file` | Cả `1` và `2` | Cú pháp rút gọn hợp nhất cả hai luồng |
| `command > /dev/null 2>&1` | Cả `1` và `2` | Chạy lệnh hoàn toàn yên lặng, nuốt sạch output và error |

---

### 2. Bảng Công Cụ Đường Ống (Pipes & Stream Filters)

| Lệnh Phối Hợp | Mục Đích Thực Chiến | Ví Dụ Tiêu Biểu |
|---|---|---|
| `command1 \| command2` | Nối `stdout` lệnh trước vào `stdin` lệnh sau | `cat app.log \| grep "ERROR"` |
| `wc -l` | Đếm tổng số dòng dữ liệu | `ps aux \| wc -l` |
| `sort -n -r` | Sắp xếp số học (`-n`) theo thứ tự giảm dần (`-r`) | `du -sh * \| sort -hr` |
| `uniq -c` | Lọc dòng trùng lặp và đếm số lần xuất hiện | `sort access.log \| uniq -c` |
| `tee file.txt` | Vừa ghi ra file vừa tiếp tục truyền qua đường ống | `build.sh \| tee build.log \| grep fail` |

---

### 3. Bảng Tìm Kiếm Nhanh Với `find` & `grep`

| Lệnh Thực Hiện | Mục Đích |
|---|---|
| `find /dir -type f -name "*.conf"` | Tìm tất cả các file có đuôi `.conf` |
| `find /dir -type d -name "logs"` | Chỉ tìm các thư mục có tên `logs` |
| `find /dir -size +100M` | Tìm các file có dung lượng lớn hơn 100MB |
| `grep -rn "API_KEY" /dir` | Tìm đệ quy từ khóa, in tên file và số dòng |
| `grep -i "error" service.log` | Tìm không phân biệt chữ hoa hay chữ thường |
| `grep -v "INFO" service.log` | Lọc ra tất cả các dòng KHÔNG chứa chữ `INFO` |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Hiểu bản chất và số hiệu của 3 luồng dữ liệu chuẩn `stdin` (0), `stdout` (1), `stderr` (2).
- [x] Biết cách dùng `2>` để bóc tách riêng log lỗi và dùng `2>&1` để gộp toàn bộ log.
- [x] Hiểu rõ vai trò của thiết bị `/dev/null` trong tự động hóa script.
- [x] Thành thạo sử dụng toán tử pipe `|` để giải quyết các bài toán lọc dữ liệu phức tạp.
- [x] Nắm vững cách dùng `tee` để nhân bản luồng dữ liệu vừa ghi file vừa truyền tiếp.
- [x] Sử dụng thành thạo `find` theo tên (`-name`), loại (`-type`), kích thước (`-size`).
- [x] Thuộc lòng cú pháp `grep -rn` để rà soát mã nguồn và cấu hình trong dự án.

---

## Lộ Trình Tiếp Theo

Sau khi hoàn tất 3 bài thực hành nền tảng về Linux (Làm quen Terminal & Điều hướng → Thao tác tệp & Thư mục → Pipe, Redirect & Tìm kiếm), bạn đã sở hữu trọn vẹn kỹ năng thao tác dòng lệnh chuyên nghiệp.

Hãy sẵn sàng bước vào bài thực hành chuyên sâu đầu tiên: **Lab 1: TCP/IP và DNS Trong DevOps**!
