# Chúc Mừng Bạn Đã Hoàn Thành Bài Thực Hành!

Bạn đã xuất sắc làm chủ toàn bộ các kỹ năng cốt lõi về **Thao Tác Tệp & Thư Mục Trong Linux**:
1. **Khởi tạo kiến trúc dự án đa tầng** với `mkdir -p`, Brace Expansion `{...}` và các phương pháp tạo tệp `touch`, `echo >`, Here-Doc.
2. **Quản trị vòng đời dữ liệu** với kỹ thuật sao chép giữ thuộc tính `cp -pv`, sao chép đệ quy `cp -r`, di chuyển/đổi tên `mv` và dọn dẹp tệp an toàn với `rm`.
3. **Đọc và giám sát luồng dữ liệu** với bộ công cụ xem tệp kinh điển `cat -n`, `less`, `head`, `tail`, `wc -l` và kỹ thuật theo dõi log trực tiếp `tail -f`.

---

## Bảng Tra Cứu Nhanh (Linux File Operations Cheat Sheet)

| Nhóm Thao Tác | Lệnh Tiêu Biểu | Cú Pháp Minh Họa | Ý Nghĩa Thực Tế Trong DevOps |
|---|---|---|---|
| **Tạo thư mục đa cấp** | `mkdir -p` | `mkdir -p app/{src,logs}` | Tạo cây thư mục phân tầng, không báo lỗi nếu đã có |
| **Tạo tệp nhanh** | `touch` | `touch app.js` | Tạo tệp rỗng hoặc cập nhật mốc thời gian sửa đổi |
| **Ghi nội dung tệp** | `echo >`, `>>` | `echo "PORT=80" > .env` | Ghi đè (`>`) hoặc ghi nối tiếp (`>>`) dữ liệu vào tệp |
| **Sao chép tệp/thư mục**| `cp`, `cp -r` | `cp a.txt b.txt`<br>`cp -r src/ backup/` | Sao lưu tệp cấu hình hoặc sao chép thư mục đệ quy |
| **Di chuyển / Đổi tên** | `mv` | `mv old.txt new.txt`<br>`mv app.log /logs/` | Đổi tên tệp hoặc di chuyển tệp sang vị trí thư mục mới |
| **Xóa tệp / thư mục** | `rm`, `rm -r` | `rm file.tmp`<br>`rm -rf temp/` | Xóa tệp đơn lẻ hoặc xóa thư mục cưỡng chế |
| **Đọc toàn bộ tệp** | `cat -n` | `cat -n config.env` | In toàn bộ nội dung tệp ra terminal kèm số dòng |
| **Cuộn đọc tệp dài** | `less` | `less /var/log/syslog` | Xem tệp theo trang, tìm kiếm `/từ_khóa`, thoát bằng `q` |
| **Trích xuất đầu/cuối** | `head`, `tail` | `head -n 5 app.log`<br>`tail -n 10 app.log` | Xem nhanh N dòng đầu tiên hoặc N dòng cuối cùng |
| **Theo dõi trực tiếp** | `tail -f` | `tail -f /var/log/service.log` | Theo dõi luồng sự kiện nhật ký theo thời gian thực |
| **Đếm số lượng dòng** | `wc -l` | `wc -l /var/log/service.log` | Kiểm tra nhanh số dòng dữ liệu trong tệp |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Sử dụng thành thạo `mkdir -p` kết hợp cú pháp ngoặc nhọn `{...}` để tạo nhanh cây thư mục dự án.
- [x] Phân biệt rõ ràng toán tử ghi đè `>` và toán tử ghi nối tiếp `>>`.
- [x] Biết cách tạo tệp cấu hình nhiều dòng sạch sẽ bằng kỹ thuật Here-Doc (`cat << 'EOF'`).
- [x] Làm chủ cờ `-r` khi sao chép thư mục bằng `cp` và nắm chắc cách dùng `mv` để đổi tên/di chuyển.
- [x] Luôn cẩn trọng khi sử dụng `rm` với ký tự đại diện `*` để không xóa nhầm dữ liệu quan trọng.
- [x] Biết khi nào nên dùng `cat`, khi nào nên dùng `less` để tránh làm tràn terminal khi đọc tệp lớn.
- [x] Nắm vững kỹ thuật `tail -f` để theo dõi các sự kiện log thời gian thực của máy chủ.

---

## Lộ Trình Tiếp Theo

Sau khi đã hoàn thiện kỹ năng làm việc với tệp và cây thư mục, bạn đã sẵn sàng tiếp tục với các bài thực hành nâng cao tiếp theo: **Tìm kiếm tệp & lọc nội dung với find/grep**, và bước vào thế giới mạng máy tính với **Lab 1: TCP/IP và DNS Trong DevOps**!
