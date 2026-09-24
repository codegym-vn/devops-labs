# Bước 2: Kỹ Thuật Multi-stage Build & Thu Nhỏ Kích Thước Image

Mặc dù image `cached-app:1.0` ở Bước 1 đã tối ưu tốc độ build nhờ tận dụng cache, kích thước của nó vẫn rất lớn. Trong bước này, chúng ta sẽ bóc tách nhược điểm của image đơn tầng và áp dụng kỹ thuật **Multi-stage Build** để cắt giảm hơn 95% dung lượng image thành phẩm.

---

## 1. Vấn Đề Của Image Đơn Tầng (Single-Stage Bloat)

Hãy kiểm tra kích thước của image bạn vừa tạo ở Bước 1:

```bash
docker images cached-app:1.0
```{{exec}}

Kích thước của nó lên tới **hơn 300 MB**!

Nguyên nhân là do base image `golang:1.22-alpine` chứa toàn bộ bộ công cụ phát triển phần mềm (Go SDK, trình biên dịch, công cụ phân tích tĩnh, thư viện header C/C++). 

Trong môi trường Production thực tế, ứng dụng khi chạy chỉ cần duy nhất file thực thi nhị phân đã biên dịch (`server`). Việc để lại trình biên dịch trong image runtime mang lại nhiều tác hại:
- **Tốn băng thông và dung lượng lưu trữ**: Kéo dài thời gian đẩy lên Registry và kéo về các worker node Kubernetes khi scale pod.
- **Mở rộng bề mặt tấn công (Attack Surface)**: Nếu kẻ tấn công đột nhập được vào container, chúng có sẵn trình biên dịch để tải mã độc dạng source code và biên dịch trực tiếp ngay trên máy chủ của bạn.

---

## 2. Bản Chất Kiến Trúc Multi-stage Build

Kỹ thuật **Multi-stage Build** cho phép bạn khai báo nhiều khối `FROM` trong cùng một file Dockerfile:
- Mỗi chỉ thị `FROM` khởi tạo một môi trường xây dựng hoàn toàn độc lập.
- Bạn có thể đặt tên định danh cho từng giai đoạn thông qua cú pháp: `FROM <image> AS <stage_name>`.
- Chỉ thị **`COPY --from=<stage_name>`** cho phép trích xuất có chọn lọc các tệp tin kết quả từ stage trước sang stage sau.

```dockerfile
# STAGE 1: Moi truong bien dich (Builder Stage)
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY main.go ./
# Bien dich tinh khong phu thuoc libc ngoai, cat bo debug symbols (-s -w)
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server main.go

# STAGE 2: Moi truong runtime sieu nhe (Runtime Stage)
FROM alpine:3.19
WORKDIR /app
# Chi sao chep duy nhat file nhi phan thanh pham tu builder
COPY --from=builder /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
```

> **Mẹo kỹ thuật về cờ biên dịch Go**:
> - `CGO_ENABLED=0`: Đảm bảo file nhị phân được liên kết tĩnh hoàn toàn (Statically linked binary), không phụ thuộc vào thư viện C runtime của hệ thống, giúp chạy mượt mà trên bất kỳ Linux distro nào (kể cả Scratch).
> - `-ldflags="-s -w"`: Loại bỏ bảng ký hiệu (Symbol table) và thông tin gỡ lỗi DWARF, giúp giảm thêm 30% kích thước file nhị phân mà không ảnh hưởng tới hiệu năng ứng dụng.

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy thiết kế một Dockerfile đa tầng để thu nhỏ tối đa dung lượng ứng dụng:

### Nhiệm vụ 1: Soạn thảo Dockerfile.multistage
1. Di chuyển vào thư mục `/root/app`:
   ```bash
   cd /root/app
   ```
2. Tạo tệp tin `/root/app/Dockerfile.multistage` với 2 giai đoạn:
   - **Giai đoạn 1 (Builder)**:
     - Base image: `golang:1.22-alpine` đặt alias là `builder`
     - Thư mục làm việc: `/app`
     - Sao chép `go.mod` và tải module trước: `COPY go.mod ./` và `RUN go mod download`
     - Sao chép mã nguồn: `COPY main.go ./`
     - Biên dịch tĩnh: `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/server main.go`
   - **Giai đoạn 2 (Runtime)**:
     - Base image: `alpine:3.19`
     - Thư mục làm việc: `/app`
     - Trích xuất file thực thi: `COPY --from=builder /app/server /app/server`
     - Cổng dịch vụ: `EXPOSE 8080`
     - Lệnh chạy: `CMD ["/app/server"]`

### Nhiệm vụ 2: Đóng gói và đối chiếu kích thước
1. Thực hiện build image đa tầng:
   ```bash
   docker build -f Dockerfile.multistage -t multistage-app:1.0 .
   ```

2. So sánh kích thước giữa hai phiên bản image:
   ```bash
   docker images | grep -E "cached-app|multistage-app"
   ```
   (Quan sát sự chênh lệch ngoạn mục: Image `multistage-app:1.0` có dung lượng chỉ xấp xỉ **15 MB**, nhỏ hơn gấp 20 lần so với phiên bản `cached-app:1.0` ban đầu).

3. Khởi chạy thử nghiệm container:
   ```bash
   docker run -d --name test-multi -p 8080:8080 multistage-app:1.0
   curl -s http://localhost:8080/healthz
   docker rm -f test-multi
   ```

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống kiểm tra Dockerfile đa tầng và dung lượng tối ưu của image `multistage-app:1.0`.
