# Bước 3: Cơ Chế Copy-on-Write & Đóng Gói Image Bằng `docker commit`

Trong các bước trước, bạn đã quan sát cách Docker tải các layer chỉ đọc (read-only) và cách các thao tác thay đổi file được ghi nhận thông qua `docker diff`. Trong bước này, chúng ta sẽ tìm hiểu sâu về cơ chế **Copy-on-Write (CoW)** và cách bảo tồn các thay đổi trong container thành một Docker Image mới bằng lệnh **`docker commit`**.

---

## 1. Cơ Chế Copy-on-Write (CoW) Hoạt Động Như Thế Nào?

Khi một container được khởi tạo từ image:
1. Docker Engine xếp chồng tất cả các Image Layers bên dưới ở chế độ **Chỉ đọc (Read-Only)**.
2. Docker gắn thêm một lớp mỏng duy nhất ở trên cùng gọi là **Container Layer** ở chế độ **Đọc-Ghi (Read-Write)**.

```
+-------------------------------------------------------+
|  Container Layer (Read-Write / Ephemeral)              | <-- Moi thay doi (tao, sua, xoa file) ghi vao day
+-------------------------------------------------------+
|  Image Layer 3: Cấu hình ứng dụng (Read-Only)          |
+-------------------------------------------------------+
|  Image Layer 2: Runtime dependencies (Read-Only)       |
+-------------------------------------------------------+
|  Image Layer 1: Base OS Rootfs (Read-Only)            |
+-------------------------------------------------------+
```

Nguyên tắc xử lý file:
- **Đọc file (Read)**: Nếu file chưa từng bị sửa đổi, tiến trình sẽ đọc trực tiếp từ layer gốc bên dưới.
- **Sửa file có sẵn (Modify - Copy-on-Write)**: Lần đầu tiên tiến trình ghi dữ liệu vào một file có sẵn trong image, storage driver (`overlay2`) sẽ tự động sao chép file đó từ lower layer (read-only) lên upper layer (read-write). Sau đó, mọi thao tác sửa đổi chỉ diễn ra trên bản sao này. Các container khác chia sẻ cùng image không hề bị ảnh hưởng.
- **Tạo mới hoặc Xóa file (Create/Delete)**: File mới được ghi trực tiếp vào Read-Write layer. Nếu xóa một file thuộc layer gốc, Docker sẽ tạo một file đánh dấu đặc biệt (*whiteout*) trên Read-Write layer để ẩn file đó đi.

> **Lưu ý vòng đời**: Khi container bị xóa (`docker rm`), toàn bộ Read-Write layer sẽ bị xóa sổ hoàn toàn khỏi đĩa cứng.

---

## 2. Lưu Trữ Trạng Thái Bằng `docker commit`

Mặc dù trong môi trường sản xuất (Production), việc xây dựng Image được tự động hóa hoàn toàn bằng **`Dockerfile`**, lệnh **`docker commit`** vẫn là công cụ không thể thiếu của kỹ sư DevOps khi:
- Cần lưu lại trạng thái (snapshot) của một container đang gặp lỗi để nhóm phát triển tái hiện và debug.
- Thực hiện các bản vá lỗi nóng (hotfix) khẩn cấp trong tình huống sự cố.
- Khám phá, cài đặt thử nghiệm các package phần mềm trước khi viết Dockerfile chính thức.

Cú pháp lệnh:
```bash
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```

Các tham số phổ biến:
- `-m, --message`: Ghi chú lý do thay đổi (tương tự git commit).
- `-a, --author`: Tên và email tác giả đóng gói image.
- `-c, --change`: Áp dụng thêm chỉ thị Dockerfile (như `ENV`, `CMD`, `EXPOSE`).

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy tự tay tạo một Image công cụ khắc phục sự cố mạng (**Troubleshooting Toolbox**) bằng cách cài đặt công cụ vào container và đóng gói lại:

### Nhiệm vụ 1: Khởi tạo container và cài đặt công cụ
1. Khởi chạy một container tương tác từ image `alpine:3.19` với tên container là **`tool-builder`**:
   ```bash
   docker run -it --name tool-builder alpine:3.19 sh
   ```
2. Bên trong shell của container, sử dụng trình quản lý gói `apk` của Alpine để cài đặt tiện ích `curl`:
   ```bash
   apk add --no-cache curl
   ```
3. Thoát khỏi container:
   ```bash
   exit
   ```
4. Kiểm tra trạng thái container bằng lệnh `docker ps -a`. Container `tool-builder` lúc này sẽ ở trạng thái **Exited**.

### Nhiệm vụ 2: Đóng gói thành Docker Image mới
1. Sử dụng lệnh `docker commit` để đóng gói container `tool-builder` thành một Image mới:
   - Tên Repository và Tag: **`devops-toolbox:v1.0`**
   - Thông điệp (`-m`): **`Add curl network tool`**
   - Tác giả (`-a`): **`DevOps Student`**

2. Xác minh Image vừa tạo:
   - Kiểm tra danh sách image:
     ```bash
     docker images devops-toolbox:v1.0
     ```
   - Chạy thử lệnh `curl` từ image mới mà không cần cài đặt lại:
     ```bash
     docker run --rm devops-toolbox:v1.0 curl --version
     ```
   - Quan sát cấu trúc layer mới được thêm vào:
     ```bash
     docker history devops-toolbox:v1.0
     ```

Sau khi hoàn thành, bấm nút **Check** để hệ thống kiểm tra image `devops-toolbox:v1.0` và công cụ `curl` đã được tích hợp sẵn sàng.
