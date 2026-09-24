# Bước 1: Cơ Chế Layer Caching & Tối Ưu Hóa Thứ Tự Chỉ Thị Trong Dockerfile

Tốc độ hoàn thành của một pipeline CI/CD phụ thuộc rất lớn vào việc Docker có tái sử dụng được bộ nhớ đệm (Build Cache) hay không. Trong bước này, bạn sẽ làm quen với khái niệm **Build Context**, quy tắc hoạt động của **Layer Caching**, và cách sắp xếp thứ tự chỉ thị để loại trừ hiện tượng **Cache Busting**.

---

## 1. Build Context & Tầm Quan Trọng Của `.dockerignore`

Khi bạn thực hiện lệnh `docker build -t my-app .`, đối số `.` chỉ định **Build Context** (ngữ cảnh bản dựng). Docker Client sẽ đóng gói toàn bộ cây thư mục này và gửi sang Docker Engine trước khi quá trình build diễn ra.

Nếu thư mục dự án chứa các file nhị phân rác, thư mục git (`.git/`), các file tài liệu hoặc biến môi trường cục bộ (`.env`), Build Context sẽ phình to không cần thiết, làm chậm đường truyền và tiềm ẩn rủi ro lộ bí mật bảo mật vào image.

Tương tự như `.gitignore`, file **`.dockerignore`** giúp loại trừ triệt để các file/thư mục không mong muốn:

```
.git
.gitignore
*.md
tmp/
```

---

## 2. Bản Chất Cơ Chế Layer Caching & Hiện Tượng Cache Busting

Mỗi chỉ thị trong Dockerfile (như `FROM`, `COPY`, `RUN`) sẽ tạo ra một lớp (layer) chỉ đọc có mã băm SHA256 đại diện cho nội dung của lớp đó:
- Đối với chỉ thị `RUN`: Docker so sánh chuỗi lệnh thực thi. Nếu chuỗi lệnh không đổi, Docker tái sử dụng layer cũ (`CACHED`).
- Đối với chỉ thị `COPY` và `ADD`: Docker tính toán mã băm checksum của các tệp tin nguồn được sao chép. Nếu nội dung tệp tin không thay đổi, Docker tái sử dụng layer cũ.

> **Quy tắc dây chuyền (Cascade Invalidation)**:
> Ngay khi một layer bị thay đổi (Cache Miss), **TẤT CẢ CÁC LAYER NẰM PHÍA SAU NÓ ĐỀU BỊ VÔ HIỆU HÓA CACHE** và buộc phải thực thi lại từ đầu.

### Phân tích phản mẫu (Anti-Pattern):
```dockerfile
# KEM TOI UU: Sao chep toan bo ma nguon roi moi tai dependencies
COPY . .
RUN go mod download
RUN go build -o server main.go
```
Khi lập trình viên chỉ chỉnh sửa một dòng comment trong file code, lệnh `COPY . .` bị đổi mã băm -> Docker buộc phải chạy lại lệnh `RUN go mod download` tải lại hàng chục megabyte thư viện từ Internet, làm thời gian build kéo dài từ vài giây lên vài phút!

### Mẫu thiết kế chuẩn (Best Practice):
```dockerfile
# CHUAN PRODUCTION: Tach biet dependency descriptor va source code
COPY go.mod ./
RUN go mod download

# Chi sao chep source code o buoc sau
COPY main.go ./
RUN go build -o server main.go
```
Khi source code thay đổi, bước `RUN go mod download` vẫn giữ nguyên trạng thái `CACHED` (mất 0.0s), quá trình build chỉ mất một tích tắc để biên dịch lại file code mới.

---

## 3. Thử Thách Thực Hành (DIY Challenge)

Hãy tối ưu hóa bộ nhớ đệm cho ứng dụng Go tại thư mục `/root/app`:

### Nhiệm vụ 1: Thiết lập `.dockerignore`
1. Di chuyển vào thư mục ứng dụng:
   ```bash
   cd /root/app
   ```
2. Khởi tạo tệp tin `/root/app/.dockerignore` chứa danh sách loại trừ sau:
   ```text
   .git
   *.md
   Dockerfile*
   ```

### Nhiệm vụ 2: Viết Dockerfile tối ưu cache và kiểm tra
1. Tạo tệp tin `/root/app/Dockerfile.cached` với các chỉ thị tuân thủ quy tắc tối ưu thứ tự cache:
   - Sử dụng base image: **`golang:1.22-alpine`**
   - Thiết lập thư mục làm việc: **`WORKDIR /app`**
   - Sao chép tệp định nghĩa module trước: **`COPY go.mod ./`**
   - Tải các module phụ thuộc: **`RUN go mod download`**
   - Sao chép mã nguồn ứng dụng: **`COPY main.go ./`**
   - Biên dịch ứng dụng tĩnh: **`RUN CGO_ENABLED=0 go build -o /app/server main.go`**
   - Khai báo cổng: **`EXPOSE 8080`**
   - Lệnh khởi chạy: **`CMD ["/app/server"]`**

2. Thực hiện đóng gói image lần 1:
   ```bash
   docker build -f Dockerfile.cached -t cached-app:1.0 .
   ```

3. Kiểm tra tính năng tận dụng cache khi sửa mã nguồn:
   - Thêm một dòng chú thích vào file `main.go`:
     ```bash
     echo "// Update comment to test caching" >> main.go
     ```
   - Build lại với tag mới `cached-app:1.1`:
     ```bash
     docker build -f Dockerfile.cached -t cached-app:1.1 .
     ```
   - Quan sát đầu ra terminal: Bạn sẽ thấy bước `RUN go mod download` hiển thị nhãn **`CACHED`** chỉ trong 0.1 giây.

4. Khởi chạy thử nghiệm container:
   ```bash
   docker run -d --name test-cached -p 8080:8080 cached-app:1.0
   curl -s http://localhost:8080/healthz
   docker rm -f test-cached
   ```

Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động kiểm tra tệp `.dockerignore`, cấu trúc Dockerfile tối ưu cache và hình ảnh image `cached-app:1.0`.
