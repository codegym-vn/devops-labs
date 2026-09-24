# Bước 1: Quản Trị Docker Images & Phân Tích Cấu Trúc Layers

Docker Image là một bản thiết kế chỉ đọc (Read-Only Template) được cấu tạo từ nhiều tầng (Layers) xếp chồng lên nhau. Việc làm chủ các câu lệnh quản trị image giúp bạn tối ưu hóa dung lượng ổ đĩa và hiểu rõ cách Docker lưu trữ mã nguồn.

---

## 1. Tìm Kiếm & Kéo Image Từ Docker Hub (`docker pull`)

Cú pháp chuẩn để tải một image từ kho lưu trữ:

```text
docker pull [repository]:[tag]
```

- Nếu không chỉ định thẻ `:tag`, Docker mặc định sẽ kéo thẻ `:latest`. Tuy nhiên, trong sản xuất (Production), **luôn chỉ định tag phiên bản cụ thể** (như `alpine:3.19`, `nginx:1.25-alpine`) để đảm bảo tính bất biến và tránh lỗi bất ngờ khi tag `latest` được cập nhật.

Thử nghiệm kéo một image tối giản Alpine Linux:

```bash
docker pull alpine:3.19
```{{exec}}

Liệt kê danh sách các image hiện có trên máy chủ:

```bash
docker images
```{{exec}}

---

## 2. Phân Tích Cấu Trúc Các Tầng Của Image (`docker history`)

Mỗi dòng lệnh trong quá trình build sẽ sinh ra một tầng layer có mã định danh SHA256 riêng biệt. Để bóc tách xem image được cấu thành từ những tầng nào, sử dụng lệnh `docker history`:

```bash
docker history alpine:3.19
```{{exec}}

Bạn sẽ thấy cột `SIZE` thể hiện dung lượng của từng layer. Nhờ cơ chế xếp tầng này:
- Nếu nhiều image dùng chung base layer (ví dụ cùng dựa trên Alpine), Docker chỉ lưu duy nhất 1 bản copy của layer đó trên ổ đĩa.
- Khi tải image mới có chung base layer, quá trình tải sẽ bỏ qua các layer đã có sẵn (`Already exists`).

---

## 3. Quản Lý Thẻ Phiên Bản (Tagging) & Dọn Dẹp Image

### Gắn Thẻ Phiên Bản Mới (`docker tag`)
Lệnh `docker tag` tạo ra một định danh tên/thẻ mới tham chiếu tới cùng một Image ID gốc (tương tự như hard link trong Linux), không làm nhân đôi dung lượng ổ đĩa:

```bash
docker tag alpine:3.19 internal-alpine:test
docker images | grep alpine
```{{exec}}

Quan sát thấy `internal-alpine:test` và `alpine:3.19` có cùng giá trị `IMAGE ID`.

### Xóa Image Không Sử Dụng (`docker rmi`)
Để xóa một tag hoặc image:

```bash
docker rmi internal-alpine:test
```{{exec}}

---

## 4. Thử Thách Thực Hành (DIY Challenge)

Hãy thực hiện quản trị image cho ứng dụng web theo các yêu cầu sau:

1. Kéo image chính thức **`nginx:alpine`** từ Docker Hub:
   ```bash
   docker pull nginx:alpine
   ```
2. Sử dụng lệnh `docker tag` để tạo một tag mới mang tên:
   **`custom-web:1.0`** từ image `nginx:alpine` vừa tải về.
3. Sử dụng lệnh `docker history` để phân tích các layer của `custom-web:1.0`.
4. Xác nhận image mới `custom-web:1.0` xuất hiện trong danh sách `docker images`.

Sau khi hoàn tất, hãy bấm nút **Check** ở góc trên để hệ thống tự động kiểm tra tag và Image ID.
