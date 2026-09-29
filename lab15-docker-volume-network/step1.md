# Bước 1: Khởi Tạo & Quản Trị Named Volume Để Lưu Trữ Dữ Liệu Bền Vững

Trong bước đầu tiên, bạn sẽ khám phá bản chất lưu trữ dữ liệu của Docker, khởi tạo **Named Volume**, và kiểm chứng khả năng bảo toàn dữ liệu xuyên suốt vòng đời của container.

---

## 1. Lý Thuyết: Bản Chất Lưu Trữ Trong Docker

Mỗi container khi chạy được xây dựng từ các image layers (chỉ đọc - Read-Only) cộng thêm một lớp mỏng có thể ghi ở trên cùng gọi là **Container Layer** (hoặc Writable Layer).

```
┌───────────────────────────────────────────────┐
│ Container Writable Layer (Tạm thời/Ephemeral) │ ◄── Bị xóa sạch khi "docker rm"
├───────────────────────────────────────────────┤
│ Image Layer 3 (Read-Only)                     │
├───────────────────────────────────────────────┤
│ Image Layer 2 (Read-Only)                     │
├───────────────────────────────────────────────┤
│ Image Layer 1 (Base OS - Read-Only)           │
└───────────────────────────────────────────────┘
```

> [!WARNING]
> Mọi file tạo ra trong Writable Layer sẽ bị **hủy vĩnh viễn** khi container bị xóa! Để lưu trữ dữ liệu bền vững (Stateful Data) như Database, Uploaded Files hoặc Logs, kỹ sư DevOps sử dụng **Named Volume**.

### Ưu điểm vượt trội của Named Volume:
1. **Độc lập với vòng đời container:** Xóa container không làm ảnh hưởng tới volume.
2. **Hiệu năng cao (I/O Performance):** Ghi trực tiếp vào hệ thống tệp tin của Host OS, không qua lớp dịch CoW (Copy-on-Write).
3. **An toàn & Dễ sao lưu:** Docker tự quản lý tại `/var/lib/docker/volumes/<volume_name>/_data`.

---

## 2. Thực Hành

### 1.1 — Khởi tạo Named Volume (`app_data`)

Chạy lệnh tạo volume mới có tên là `app_data`:

```bash
docker volume create app_data
```{{exec}}

Liệt kê danh sách volume trên hệ thống:

```bash
docker volume ls
```{{exec}}

### 1.2 — Kiểm tra thông tin cấu hình Volume

Sử dụng lệnh `inspect` để xem thông tin chi tiết (Mountpoint, Driver, thời gian tạo):

```bash
docker volume inspect app_data
```{{exec}}

Quan sát trường `"Mountpoint"`: Đường dẫn thực tế trên máy host chính là `/var/lib/docker/volumes/app_data/_data`.

---

### 1.3 — Gắn Volume vào Container đầu tiên (`writer-box`)

Khởi chạy container `writer-box`, gắn volume `app_data` vào thư mục `/data` bên trong container và ghi dữ liệu mẫu:

```bash
docker run -d --name writer-box \
  -v app_data:/data \
  alpine:3.19 \
  sh -c "echo 'DevOps Data Persistence 2026' > /data/message.txt && sleep 3600"
```{{exec}}

Đọc kiểm tra file vừa được tạo bên trong container:

```bash
docker exec writer-box cat /data/message.txt
```{{exec}}

---

### 1.4 — Xóa bỏ Container `writer-box`

Tiến hành xóa cưỡng chế container `writer-box` để mô phỏng sự cố hoặc nâng cấp phiên bản ứng dụng:

```bash
docker rm -f writer-box
```{{exec}}

Kiểm tra lại danh sách volume:

```bash
docker volume ls
```{{exec}}

Volume `app_data` vẫn tồn tại nguyên vẹn!

---

### 1.5 — Khởi chạy Container thứ hai (`reader-box`) và đọc lại dữ liệu

Khởi chạy một container hoàn toàn mới tên là `reader-box` và gắn cùng volume `app_data` vào thư mục `/data`:

```bash
docker run -d --name reader-box \
  -v app_data:/data \
  alpine:3.19 \
  sleep 3600
```{{exec}}

Đọc nội dung file `/data/message.txt` từ container `reader-box`:

```bash
docker exec reader-box cat /data/message.txt
```{{exec}}

Bạn sẽ thấy nội dung `DevOps Data Persistence 2026` vẫn tồn tại chính xác!

---

## 3. Hoàn Thành & Xác Minh

Nhấn nút **Check** ở góc dưới bên trái để hệ thống tự động kiểm tra:
1. Volume `app_data` tồn tại.
2. Container `reader-box` đang ở trạng thái `running` và được gắn volume `app_data` vào mount point `/data`.
3. Tệp tin `/data/message.txt` tồn tại và chứa đúng chuỗi văn bản dữ liệu đã ghi.
