# Bước 2: Thao Tác Container Tương Tác & Sao Chép Dữ Liệu CLI

Trong công việc hàng ngày, kỹ sư DevOps thường xuyên phải thâm nhập vào container để gỡ lỗi (debug), kiểm tra cấu hình mạng, hoặc sao chép các file cấu hình và dữ liệu nhật ký giữa máy chủ host và container.

---

## 1. Chạy Container Ở Chế Độ Tương Tác (`docker run -it`)

Cờ `-it` là sự kết hợp của 2 tham số:
- **`-i` (interactive)**: Giữ luồng nhập chuẩn (STDIN) mở, cho phép bạn gửi lệnh từ bàn phím vào container.
- **`-t` (pseudo-TTY)**: Cấp phát một terminal ảo Linux hoàn chỉnh (có dấu nhắc lệnh, hỗ trợ phím mũi tên, màu sắc).

Thử nghiệm mở một shell tương tác bên trong container Alpine:

```bash
docker run -it --rm alpine:3.19 sh
```{{exec}}

Bạn đang ở bên trong container. Hãy gõ thử các lệnh Linux:
```bash
uname -a
cat /etc/os-release
exit
```{{exec}}

Cờ `--rm` đảm bảo rằng ngay khi bạn gõ `exit`, container sẽ tự động được xóa bỏ sạch sẽ để tránh rác ổ đĩa.

---

## 2. Thâm Nhập Container Đang Chạy Nền (`docker exec -it`)

Khác với `docker run` (tạo ra một container mới tinh), lệnh `docker exec` cho phép bạn **chạy thêm một tiến trình phụ bên trong một container ĐANG HOẠT ĐỘNG** mà không làm gián đoạn dịch vụ chính.

Khởi chạy một web server Nginx chạy ngầm:

```bash
docker run -d --name demo-nginx -p 8081:80 nginx:alpine
```{{exec}}

Sử dụng `docker exec` để mở shell tương tác bên trong `demo-nginx`:

```bash
docker exec -it demo-nginx sh -c "cat /etc/nginx/conf.d/default.conf | head -n 10"
```{{exec}}

Dọn dẹp container demo:

```bash
docker rm -f demo-nginx
```{{exec}}

---

## 3. Sao Chép File 2 Chiều (`docker cp`) & Đối Soát Thay Đổi (`docker diff`)

### Sao Chép Dữ Liệu (`docker cp`)
Lệnh `docker cp` hoạt động tương tự lệnh `scp` trong Linux, cho phép truyền file qua lại giữa máy chủ host và container mà không cần cài đặt SSH hay mở thêm cổng mạng:
- Từ Host vào Container: `docker cp /path/file.txt container_name:/path/file.txt`
- Từ Container ra Host: `docker cp container_name:/path/file.txt /path/file.txt`

### Đối Soát Thay Đổi Hệ Thống File (`docker diff`)
Nhờ storage driver `overlay2`, mọi file bị tác động trong container đều được theo dõi:
- **`A` (Added)**: File hoặc thư mục được tạo mới.
- **`C` (Changed)**: File hoặc thư mục có sẵn bị sửa đổi nội dung.
- **`D` (Deleted)**: File hoặc thư mục bị xóa.

---

## 4. Thử Thách Thực Hành (DIY Challenge)

Hãy thực hành cập nhật nội dung giao diện cho web server Nginx bằng các lệnh CLI:

1. Khởi chạy một container Nginx chạy ngầm:
   - Tên container: **`my-web`**
   - Image: **`nginx:alpine`**
   - Chế độ chạy: Background daemon (**`-d`**)
   - Ánh xạ cổng: Cổng host **`8080`** trỏ vào cổng container **`80`** (**`-p 8080:80`**)
2. Sao chép file HTML mẫu có sẵn tại **`/root/sample-site/index.html`** vào trong container tại đường dẫn:
   **`/usr/share/nginx/html/index.html`** bằng lệnh `docker cp`.
3. Kiểm tra kết quả hiển thị của website:
   ```bash
   curl -s http://localhost:8080
   ```
   (Nội dung trả về phải chứa dòng tiêu đề *"DevOps Custom Web"*).
4. Sử dụng lệnh `docker diff my-web` để kiểm tra ghi nhận thay đổi file trên hệ thống.

Sau khi hoàn thành, hãy bấm nút **Check** ở góc trên để hệ thống tự động kiểm tra giao diện web và trạng thái file trong container.
