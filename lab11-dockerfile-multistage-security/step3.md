# Bước 3: Siết Chặt Bảo Mật Container Bằng Phân Quyền Non-Root User

Sau khi đã tối ưu cache ở Bước 1 và giảm dung lượng image ở Bước 2, một vấn đề sống còn cần giải quyết trước khi đưa ứng dụng lên môi trường Production là **Bảo mật tiến trình thực thi**. Trong bước này, bạn sẽ nhận diện mối nguy khi chạy container bằng quyền `root` và cấu hình phân quyền người dùng **Non-Root** chuẩn **Principle of Least Privilege**.

---

## 1. Mối Nguy Hiểm Khi Chạy Container Dưới Quyền Root (UID 0)

Theo mặc định, nếu trong Dockerfile bạn không khai báo chỉ thị `USER`, Docker Engine sẽ khởi chạy toàn bộ tiến trình ứng dụng bằng người dùng **`root` (UID = 0)**.

Hãy nhớ rằng: Container không phải là máy ảo phần cứng hoàn chỉnh, mà chỉ là các tiến trình Linux bị cô lập bằng Namespaces và cgroups trên cùng một nhân Kernel của máy chủ host:
- Nếu ứng dụng web tồn tại lỗ hổng bảo mật (ví dụ như Remote Code Execution - RCE, chèn lệnh hệ điều hành), hacker sẽ ngay lập tức chiếm được quyền `root` bên trong container.
- Khi kết hợp với các lỗ hổng nhân Linux hoặc các lỗ hổng cấu hình (như bind mount socket `/var/run/docker.sock`, cấp quyền `SYS_ADMIN`), kẻ tấn công có thể thực hiện kỹ thuật **Container Breakout** (thoát khỏi container) để chiếm quyền kiểm soát toàn bộ máy chủ vật lý.

> **Tiêu chuẩn bảo mật bắt buộc**:
> - Các bộ tiêu chuẩn như **CIS Docker Benchmark**, **PCI-DSS**, và **Kubernetes Pod Security Standards** (`runAsNonRoot: true`) đều nghiêm cấm việc chạy container bằng quyền root trong môi trường thực tế.

---

## 2. Thiết Lập Người Dùng Non-Root Trong Dockerfile

Để loại trừ hoàn toàn nguy cơ trên, chúng ta áp dụng nguyên tắc đặc quyền tối thiểu:

### Tạo người dùng và nhóm riêng biệt
Trong Alpine Linux, sử dụng lệnh `addgroup` và `adduser`:
```dockerfile
# Tao group he thong (-S) voi GID 10001
# Tao user he thong (-S) voi UID 10001 gan vao group tren
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup
```

### Chuyển giao quyền sở hữu file (Ownership)
Khi copy file từ builder sang runtime, hãy gắn cờ `--chown` để người dùng non-root có quyền đọc và thực thi:
```dockerfile
COPY --chown=10001:10001 --from=builder /app/server /app/server
```

### Chỉ thị chuyển đổi người dùng (`USER`)
Khai báo chỉ thị `USER` ở cuối Dockerfile trước `CMD`:
```dockerfile
USER 10001:10001
```

> **Tại sao nên dùng ID dạng số (`10001:10001`) thay vì chữ (`appuser`)?**
> Khi triển khai trên Kubernetes với chính sách `runAsNonRoot: true`, Kubernetes kubelet sẽ kiểm tra UID trực tiếp từ metadata của image trước khi tải file `/etc/passwd`. Việc khai báo số nguyên tường minh giúp Kubernetes xác thực tính hợp lệ ngay lập tức mà không cần đọc filesystem.

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy hoàn thiện tệp Dockerfile chính thức tại `/root/app/Dockerfile` tích hợp toàn bộ các kỹ thuật đã học:

### Nhiệm vụ 1: Soạn thảo Dockerfile chuẩn Production
1. Di chuyển vào `/root/app`:
   ```bash
   cd /root/app
   ```
2. Tạo tệp tin `/root/app/Dockerfile` với đầy đủ các tiêu chuẩn:
   - **Giai đoạn 1 (Builder)**:
     - Base image: `golang:1.22-alpine AS builder`
     - Thư mục làm việc: `/app`
     - Sao chép `go.mod` và chạy `go mod download`
     - Sao chép `main.go`
     - Biên dịch tĩnh: `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server main.go`
   - **Giai đoạn 2 (Hardened Runtime)**:
     - Base image: `alpine:3.19`
     - Thư mục làm việc: `/app`
     - Tạo group `appgroup` (GID 10001) và user `appuser` (UID 10001)
     - Sao chép file thực thi có gán quyền: `COPY --chown=10001:10001 --from=builder /app/server /app/server`
     - Chỉ định user thực thi: `USER 10001:10001`
     - Cổng dịch vụ: `EXPOSE 8080`
     - Lệnh chạy: `CMD ["/app/server"]`

### Nhiệm vụ 2: Đóng gói và kiểm tra bảo mật
1. Thực hiện build image chuẩn:
   ```bash
   docker build -t secure-app:1.0 .
   ```

2. Khởi chạy container chính thức ở chế độ chạy ngầm:
   ```bash
   docker run -d --name secure-app-container -p 8080:8080 secure-app:1.0
   ```

3. Xác thực quyền hạn người dùng thông qua API `/user` của ứng dụng:
   ```bash
   curl -s http://localhost:8080/user
   ```
   (Kết quả JSON trả về phải hiển thị rõ: `"uid": 10001`, `"is_root": false`).

4. Kiểm tra ID thực tế từ hệ thống Linux bên trong container:
   ```bash
   docker exec secure-app-container id
   ```
   (Đầu ra phải hiển thị `uid=10001(appuser) gid=10001(appgroup)`).

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động kiểm tra Dockerfile bảo mật, trạng thái của `secure-app:1.0` và quyền non-root của tiến trình.
