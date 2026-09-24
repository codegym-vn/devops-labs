# Bước 2: Kỹ Thuật Multi-stage Build & Thu Nhỏ Kích Thước Image

Mặc dù image `cached-app:1.0` ở Bước 1 đã tối ưu tốc độ build nhờ tận dụng cache, kích thước của nó vẫn rất lớn. Trong bước này, chúng ta sẽ phân tích nhược điểm của image đơn tầng và áp dụng kỹ thuật **Multi-stage Build** để cắt giảm hơn 95% dung lượng.

---

## 1. Vấn Đề Của Image Đơn Tầng (Single-Stage Bloat)

Hãy kiểm tra kích thước của image bạn vừa tạo ở Bước 1:

```bash
docker images cached-app:1.0
```{{exec}}

Kích thước của nó lên tới **hơn 300 MB**.

Nguyên nhân là do base image `golang:1.22-alpine` chứa toàn bộ bộ công cụ phát triển (Go SDK, trình biên dịch, thư viện header). Trong môi trường Production, ứng dụng khi chạy chỉ cần duy nhất file thực thi nhị phân đã biên dịch. Việc để lại trình biên dịch trong image runtime mang lại nhiều tác hại:

- **Tốn băng thông và dung lượng**: Kéo dài thời gian đẩy lên Registry và kéo về các worker node Kubernetes khi scale pod.
- **Mở rộng bề mặt tấn công**: Nếu kẻ tấn công đột nhập được vào container, chúng có sẵn trình biên dịch để tải và biên dịch mã độc trực tiếp.

---

## 2. Bản Chất Kiến Trúc Multi-stage Build

Kỹ thuật **Multi-stage Build** cho phép bạn khai báo nhiều khối `FROM` trong cùng một Dockerfile:

- Mỗi chỉ thị `FROM` khởi tạo một môi trường xây dựng hoàn toàn độc lập.
- Đặt tên cho từng giai đoạn: `FROM <image> AS <stage_name>`.
- Chỉ thị **`COPY --from=<stage_name>`** cho phép trích xuất có chọn lọc tệp tin kết quả từ stage trước sang stage sau.

```dockerfile
# STAGE 1: Moi truong bien dich (Builder Stage)
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY main.go ./
# Bien dich tinh, cat bo debug symbols (-s -w)
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server main.go

# STAGE 2: Moi truong runtime sieu nhe (Runtime Stage)
FROM alpine:3.19
WORKDIR /app
# Chi sao chep duy nhat file nhi phan tu builder
COPY --from=builder /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
```

> **Ghi chu ve co bien dich Go**:
> - `CGO_ENABLED=0`: File nhi phan duoc lien ket tinh hoan toan, khong phu thuoc thu vien C runtime, chay muot ma tren bat ky Linux distro nao.
> - `-ldflags="-s -w"`: Loai bo bang ky hieu va thong tin debug DWARF, giam them 30% kich thuoc file nhi phan.

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy thiết kế Dockerfile đa tầng để thu nhỏ tối đa dung lượng ứng dụng.

### Nhiệm vụ 1: Soạn thảo Dockerfile.multistage

Di chuyển vào thư mục `/root/app`:

```bash
cd /root/app
```

Tạo tệp tin `/root/app/Dockerfile.multistage` với 2 giai đoạn:

- **Giai đoạn 1 (Builder)**:
  - Base image: `golang:1.22-alpine` đặt alias là `builder`
  - Thư mục làm việc: `/app`
  - Sao chép `go.mod` và tải module: `COPY go.mod ./` rồi `RUN go mod download`
  - Sao chép mã nguồn: `COPY main.go ./`
  - Biên dịch tĩnh: `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server main.go`
- **Giai đoạn 2 (Runtime)**:
  - Base image: `alpine:3.19`
  - Thư mục làm việc: `/app`
  - Trích xuất file thực thi: `COPY --from=builder /app/server /app/server`
  - Cổng dịch vụ: `EXPOSE 8080`
  - Lệnh chạy: `CMD ["/app/server"]`

### Nhiệm vụ 2: Đóng gói và đối chiếu kích thước

Build image đa tầng:

```bash
docker build -f Dockerfile.multistage -t multistage-app:1.0 .
```

So sánh kích thước giữa hai phiên bản:

```bash
docker images | grep -E "cached-app|multistage-app"
```

Kết quả: Image `multistage-app:1.0` có dung lượng chỉ xấp xỉ **15 MB**, nhỏ hơn gấp 20 lần so với `cached-app:1.0`.

Khởi chạy thử nghiệm:

```bash
docker run -d --name test-multi -p 8080:8080 multistage-app:1.0
curl -s http://localhost:8080/healthz
docker rm -f test-multi
```

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống kiểm tra Dockerfile đa tầng và dung lượng tối ưu của image `multistage-app:1.0`.
