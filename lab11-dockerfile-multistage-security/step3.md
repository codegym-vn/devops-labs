# Bước 3: Siết Chặt Bảo Mật Container Bằng Phân Quyền Non-Root User

Sau khi đã tối ưu cache ở Bước 1 và giảm dung lượng image ở Bước 2, vấn đề cuối cùng cần giải quyết trước khi đưa ứng dụng lên Production là **bảo mật tiến trình thực thi**. Trong bước này, bạn sẽ nhận diện mối nguy khi chạy container bằng quyền `root` và cấu hình phân quyền **Non-Root** chuẩn Principle of Least Privilege.

---

## 1. Mối Nguy Hiểm Khi Chạy Container Dưới Quyền Root

Theo mặc định, nếu Dockerfile không khai báo chỉ thị `USER`, Docker Engine sẽ khởi chạy toàn bộ tiến trình bằng người dùng **root (UID 0)**.

Container không phải là máy ảo phần cứng hoàn chỉnh, mà chỉ là các tiến trình Linux bị cô lập bằng Namespaces và cgroups trên cùng nhân Kernel của máy chủ host:

- Nếu ứng dụng web tồn tại lỗ hổng bảo mật (Remote Code Execution, chèn lệnh hệ điều hành), hacker sẽ ngay lập tức chiếm được quyền root bên trong container.
- Khi kết hợp với lỗ hổng nhân Linux hoặc cấu hình sai (bind mount `/var/run/docker.sock`, cấp quyền `SYS_ADMIN`), kẻ tấn công có thể thực hiện **Container Breakout** để chiếm quyền kiểm soát máy chủ vật lý.

> **Tiêu chuẩn bảo mật bắt buộc**: CIS Docker Benchmark, PCI-DSS, và Kubernetes Pod Security Standards (`runAsNonRoot: true`) đều nghiêm cấm chạy container bằng quyền root trong môi trường Production.

---

## 2. Thiết Lập Người Dùng Non-Root Trong Dockerfile

Để loại trừ hoàn toàn nguy cơ trên, chúng ta áp dụng nguyên tắc đặc quyền tối thiểu qua 3 bước:

### Tạo người dùng và nhóm riêng biệt

Trong Alpine Linux, sử dụng lệnh `addgroup` và `adduser`:

```dockerfile
# Tao group he thong (-S) voi GID 10001
# Tao user he thong (-S) voi UID 10001, gan vao group
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup
```

### Chuyển giao quyền sở hữu file

Khi copy file từ builder sang runtime, gắn cờ `--chown` để người dùng non-root có quyền đọc và thực thi:

```dockerfile
COPY --chown=10001:10001 --from=builder /app/server /app/server
```

### Chỉ thị chuyển đổi người dùng

Khai báo chỉ thị `USER` ở cuối Dockerfile trước `CMD`:

```dockerfile
USER 10001:10001
```

> **Tai sao nen dung ID dang so thay vi dang chu?** Khi trien khai tren Kubernetes voi chinh sach `runAsNonRoot: true`, kubelet kiem tra UID truc tiep tu metadata cua image truoc khi doc file `/etc/passwd`. Khai bao so nguyen giup Kubernetes xac thuc tinh hop le ngay lap tuc.

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy hoàn thiện Dockerfile chính thức tại `/root/app/Dockerfile` tích hợp toàn bộ kỹ thuật đã học.

### Nhiệm vụ 1: Soạn thảo Dockerfile chuẩn Production

Di chuyển vào `/root/app`:

```bash
cd /root/app
```

Tạo tệp tin `/root/app/Dockerfile` với đầy đủ các tiêu chuẩn:

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

Build image chuẩn:

```bash
docker build -t secure-app:1.0 .
```

Khởi chạy container chính thức:

```bash
docker run -d --name secure-app-container -p 8080:8080 secure-app:1.0
```

Xác thực quyền hạn người dùng thông qua API:

```bash
curl -s http://localhost:8080/user
```

Kết quả JSON phải hiển thị: `"uid": 10001`, `"is_root": false`.

Kiểm tra ID thực tế từ bên trong container:

```bash
docker exec secure-app-container id
```

Kết quả: `uid=10001(appuser) gid=10001(appgroup)`.

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động kiểm tra Dockerfile bảo mật, image `secure-app:1.0` và quyền non-root của tiến trình.
