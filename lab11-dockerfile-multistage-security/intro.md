# Lab 11: Thiết Kế Dockerfile Multi-stage, Tối Ưu Cache & Phân Quyền Non-Root

Chào mừng bạn đến với bài thực hành chuyên sâu về **Kỹ Thuật Viết Dockerfile Chuẩn Production: Tối Ưu Tốc Độ Build, Giảm Thiểu Dung Lượng và Gia Cố Bảo Mật**!

Trong môi trường triển khai thực tế (CI/CD Pipelines, Kubernetes Cluster), một Dockerfile được viết cẩu thả sẽ kéo theo hàng loạt hệ lụy: thời gian build kéo dài do mất cache, kích thước image phình to hàng trăm megabyte làm chậm quá trình kéo image (image pull latency), và đặc biệt là rủi ro bảo mật nghiêm trọng khi chạy tiến trình dưới quyền `root (UID 0)`.

---

## 1. Sơ Đồ So Sánh Kiến Trúc Dockerfile

![Kiến Trúc Dockerfile Multi-stage](/lab11-dockerfile-multistage-security/architecture.svg)

---

## 2. Bảng Đối Chiếu: Dockerfile Sơ Khai vs Chuẩn Production

| Tiêu Chí Kỹ Thuật | Dockerfile Sơ Khai (Anti-Pattern) | Dockerfile Chuẩn Production (Best Practice) |
| :--- | :--- | :--- |
| **Cơ chế Cache** | `COPY . .` trước khi nạp thư viện -> vỡ cache mỗi lần sửa code | `COPY go.mod` & download thư viện trước -> tận dụng 100% cache |
| **Kiến trúc Build** | Single-stage nguyên khối, chứa cả SDK biên dịch và mã nguồn | Multi-stage build tách biệt giai đoạn Builder và Runtime |
| **Kích thước Image** | Rất nặng (**> 300 MB** cho Golang, > 1GB cho Node.js/Java) | Siêu nhẹ (**~15 MB** với Alpine base, giảm hơn 95% dung lượng) |
| **Bề mặt tấn công** | Rộng: chứa trình biên dịch (compiler), shell, debug tools | Tối thiểu: chỉ chứa duy nhất file thực thi nhị phân tĩnh |
| **Phân quyền chạy** | Mặc định `root (UID 0)` -> nguy cơ leo thang đặc quyền | Khởi tạo nhóm/người dùng chuyên biệt (`USER 10001:10001`) |
| **Tương thích K8s** | Vi phạm chính sách bảo mật Pod Security Standards | Đạt chuẩn `runAsNonRoot: true`, sẵn sàng cho Production |

---

## 3. Lộ Trình 3 Bước Thực Hành

1. **Bước 1: Cơ Chế Layer Caching & Tối Ưu Hóa Thứ Tự Chỉ Thị Trong Dockerfile**
   - Phân tích cơ chế băm nội dung của Docker Build Engine và hiện tượng Cache Busting.
   - Sử dụng `.dockerignore` để loại trừ các tệp tin thừa khỏi Build Context.
   - Tái sắp xếp các lệnh `COPY` và `RUN` để tái sử dụng tối đa cache khi mã nguồn thay đổi.
2. **Bước 2: Kỹ Thuật Multi-stage Build & Thu Nhỏ Kích Thước Image**
   - Tách biệt môi trường Build (Builder stage) và môi trường thực thi (Runtime stage).
   - Sử dụng cờ biên dịch tĩnh `CGO_ENABLED=0` và cờ cắt giảm ký hiệu debug `-ldflags="-s -w"`.
   - Giảm dung lượng từ hơn 300MB xuống chỉ còn khoảng 15MB với base image `alpine:3.19`.
3. **Bước 3: Siết Chặt Bảo Mật Container Bằng Phân Quyền Non-Root User**
   - Nhận diện rủi ro của người dùng `root` bên trong container đối với máy chủ host.
   - Áp dụng nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege): tạo nhóm/người dùng chuyên biệt với UID/GID cố định.
   - Chuyển giao quyền sở hữu file và áp dụng chỉ thị `USER 10001:10001`.
   - Kiểm chứng quyền hạn thực tế của tiến trình qua các API hệ thống.

Hãy bấm **Start** hoặc chọn **Bước 1** ở thanh điều hướng để bắt đầu tối ưu hóa Dockerfile!
