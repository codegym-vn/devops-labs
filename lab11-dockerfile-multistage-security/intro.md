Chào mừng bạn đến với bài thực hành chuyên sâu về **Kỹ Thuật Viết Dockerfile Chuẩn Production**.

Trong môi trường triển khai thực tế (CI/CD Pipelines, Kubernetes Cluster), một Dockerfile được viết cẩu thả sẽ kéo theo hàng loạt hệ lụy: thời gian build kéo dài do mất cache, kích thước image phình to hàng trăm megabyte làm chậm quá trình kéo image, và đặc biệt là rủi ro bảo mật nghiêm trọng khi chạy tiến trình dưới quyền `root (UID 0)`.

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:

1. **Làm chủ cơ chế Layer Caching** của Docker Build Engine: hiểu quy tắc vô hiệu hóa dây chuyền (Cascade Invalidation), sắp xếp thứ tự chỉ thị để tận dụng 100% cache khi mã nguồn thay đổi.
2. **Thành thạo kỹ thuật Multi-stage Build**: tách biệt hoàn toàn môi trường biên dịch (Builder) và môi trường thực thi (Runtime), giảm dung lượng image từ hơn 300MB xuống chỉ còn khoảng 15MB.
3. **Siết chặt bảo mật container bằng Non-Root User**: tạo người dùng chuyên biệt với UID/GID cố định, đáp ứng chuẩn CIS Docker Benchmark và Kubernetes Pod Security Standards.

---

## So Sánh Kiến Trúc: Dockerfile Sơ Khai vs Chuẩn Production

| Tiêu Chí | Dockerfile Sơ Khai (Anti-Pattern) | Dockerfile Chuẩn Production (Best Practice) |
| :--- | :--- | :--- |
| **Cơ chế Cache** | `COPY . .` trước khi nạp thư viện -> vỡ cache mỗi lần sửa code | `COPY go.mod` -> `go mod download` trước -> tận dụng 100% cache |
| **Kiến trúc Build** | Single-stage nguyên khối, chứa cả SDK biên dịch và mã nguồn | Multi-stage build tách biệt giai đoạn Builder và Runtime |
| **Kích thước Image** | Rất nặng (> 300 MB cho Golang, > 1GB cho Node.js/Java) | Siêu nhẹ (~15 MB với Alpine, giảm hơn 95% dung lượng) |
| **Bề mặt tấn công** | Rộng: chứa compiler, shell, debug tools | Tối thiểu: chỉ chứa duy nhất file nhị phân tĩnh |
| **Phân quyền chạy** | Mặc định `root (UID 0)` -> nguy cơ leo thang đặc quyền | Người dùng chuyên biệt `USER 10001:10001` |
| **Tương thích K8s** | Vi phạm Pod Security Standards | Đạt chuẩn `runAsNonRoot: true`, sẵn sàng cho Production |

---

## Lộ Trình 3 Bước Thực Hành

1. **Bước 1 - Layer Caching**: Phân tích cơ chế băm nội dung, thiết lập `.dockerignore`, sắp xếp thứ tự `COPY` và `RUN` để tối đa hóa cache.
2. **Bước 2 - Multi-stage Build**: Tách Builder và Runtime, sử dụng cờ biên dịch tĩnh `CGO_ENABLED=0` và `-ldflags="-s -w"`, giảm image từ 300MB xuống 15MB.
3. **Bước 3 - Non-Root Security**: Tạo người dùng non-root, gán quyền sở hữu file với `--chown`, kiểm chứng quyền hạn tiến trình qua API hệ thống.

---

## Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường**: Mã nguồn Go, Dockerfile mẫu và Docker base image được hệ thống tự động chuẩn bị ngầm.
- **Thực thi lệnh nhanh**: Bấm trực tiếp vào các khối lệnh code trên hướng dẫn để tự động gửi và chạy lệnh trên terminal bên phải.
- **Xác thực tự động**: Mỗi bước đều có phần **Thử Thách**. Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động chấm điểm kết quả.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu tối ưu hóa Dockerfile!
