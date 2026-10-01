# Thao Tác Tệp & Thư Mục Trong Linux

Chào mừng bạn đến với bài thực hành: **Thao Tác Tệp & Thư Mục Trong Linux**.

Trong công việc hàng ngày của kỹ sư DevOps (**CI/CD, Cloud Infrastructure, Docker, Kubernetes**), phần lớn thời gian bạn sẽ thao tác trực tiếp với các tệp tin và cây thư mục trên máy chủ:
- Tạo dựng cấu trúc phân tầng cho dự án microservices (`src`, `config`, `logs`, `bin`).
- Sao lưu các tệp cấu hình trước khi cập nhật (`cp nginx.conf nginx.conf.bak`).
- Di chuyển và dọn dẹp các tệp bản ghi cũ hoặc tệp tạm thời trong quá trình đóng gói.
- Đọc, kiểm tra và theo dõi luồng log ứng dụng thời gian thực để chẩn đoán sự cố kịp thời.

---

## 1. Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Khởi tạo kiến trúc thư mục đa tầng:** Thành thạo lệnh `mkdir -p` kết hợp kỹ thuật Brace Expansion của Bash để dựng toàn bộ cây thư mục dự án chỉ với một dòng lệnh.
2. **Quản trị vòng đời tệp tin:** Sử dụng linh hoạt `touch`, `echo >` và Here-Doc (`cat << 'EOF'`) để tạo và cập nhật dữ liệu tệp tin.
3. **Sao chép, di chuyển, đổi tên và xóa an toàn:** Làm chủ các cờ hiệu quan trọng của `cp` (`-r`, `-p`, `-v`), cơ chế của `mv` và các quy tắc sống còn khi dùng `rm` để tránh xóa nhầm dữ liệu.
4. **Đọc và giám sát nội dung tệp:** Sử dụng thành thạo bộ công cụ xem tệp kinh điển gồm `cat`, `less`, `head`, `tail`, và kỹ thuật theo dõi luồng log thời gian thực với `tail -f`.

---

## 2. Bảng Tổng Hợp Các Lệnh Thao Tác Cốt Lõi

| Nhóm Thao Tác | Lệnh Tiêu Biểu | Cú Pháp Ví Dụ | Mục Đích Thực Tế |
|---|---|---|---|
| **Tạo mới** | `mkdir`, `touch` | `mkdir -p app/{src,logs}`<br>`touch app/app.py` | Tạo cây thư mục đa cấp và tạo tệp tin nhanh |
| **Sao chép** | `cp`, `cp -r` | `cp file.conf file.conf.bak`<br>`cp -r src/ backup/` | Sao lưu tệp cấu hình hoặc sao chép thư mục đệ quy |
| **Di chuyển / Đổi tên** | `mv` | `mv old.txt new.txt`<br>`mv *.log /var/log/archive/` | Đổi tên tệp hoặc di chuyển tệp sang thư mục đích |
| **Xóa dữ liệu** | `rm`, `rmdir` | `rm file.tmp`<br>`rm -rf temp_build/` | Dọn dẹp tệp tin rác và thư mục tạm thời |
| **Xem nội dung** | `cat`, `less` | `cat -n config.env`<br>`less /var/log/syslog` | Đọc toàn bộ nội dung hoặc cuộn trang đọc tệp dài |
| **Trích xuất & Giám sát**| `head`, `tail` | `head -n 10 file.log`<br>`tail -f service.log` | Xem dòng đầu, dòng cuối hoặc theo dõi log trực tiếp |

---

## 3. Tính Năng Tương Tác Trên Killercoda

- **Môi trường được chuẩn bị tự động:** Toàn bộ công cụ hỗ trợ và các tệp dữ liệu giả lập (như tệp nhật ký ứng dụng 50 dòng) đã được chuẩn bị sẵn ở chế độ nền.
- **Thực thi lệnh nhanh:** Bạn có thể nhấn trực tiếp vào các khối mã lệnh trên bảng hướng dẫn để gửi lệnh sang terminal mà không cần sao chép.
- **Chấm điểm tự động:** Mỗi bước đều có phần Thử Thách kèm nút **Check** ở góc trên để hệ thống tự động đánh giá và chấm điểm bài làm của bạn.

Bấm **START** hoặc chọn **Bước 1** ở thanh điều hướng để bắt đầu!
