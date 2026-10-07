# Bước 3: Tối Ưu Dockerfile Multi-stage & Vá Lỗ Hổng Triệt Để

Để xử lý triệt để các lỗ hổng nhân hệ điều hành và các lỗi cấu hình sai trong Dockerfile, chúng ta áp dụng kỹ thuật **Container Hardening** với mô hình xây dựng đa tầng (Multi-stage Build).

---

### 1. Ba nguyên tắc thiết kế Container chuẩn Production

1. **Sử dụng Base Image cập nhật và tối giản:** Chuyển từ `node:16-alpine` sang `node:20-alpine` (phiên bản LTS hiện đại, thường xuyên nhận các bản cập nhật bảo mật nhân Linux).
2. **Kỹ thuật Multi-stage Build:**
   * **Stage 1 (Builder):** Dùng để cài đặt các thư viện cần thiết.
   * **Stage 2 (Runtime):** Chỉ sao chép đúng những tệp thực sự cần để chạy ứng dụng (`server.js` và thư mục `node_modules` production), loại bỏ hoàn toàn các tiện ích dư thừa như `curl`, `bash`, hay trình biên dịch mã.
3. **Phân quyền người dùng phi đặc quyền (Non-root user):** Khai báo chỉ thị `USER node` (UID 1000) có sẵn trong image Alpine. Container sẽ không thể thao tác với các tệp tin hệ thống của máy chủ Host.

---

### 2. Tạo tệp Dockerfile.secure

Tạo tệp cấu hình đóng gói chuẩn an ninh:

```bash
cd /root/container-security-lab
cat << 'EOF' > Dockerfile.secure
# Stage 1: Chuan bi dependencies
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime moi truong Production
FROM node:20-alpine
WORKDIR /app

ENV NODE_ENV=production

# Chi copy nhung thanh phan toi thieu tu stage builder
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY server.js ./

# Thiet lap quyen so huu thu muc va chay bang user phi dac quyen
RUN chown -R node:node /app
USER node

EXPOSE 3000
CMD ["node", "server.js"]
EOF
cat Dockerfile.secure
```{{exec}}

---

### 3. Đóng gói Docker Image phiên bản v2

Xây dựng image `payment-service:v2` sử dụng Dockerfile an toàn:

```bash
docker build -t payment-service:v2 -f Dockerfile.secure .
```{{exec}}

So sánh kích thước giữa phiên bản v1 và v2:

```bash
docker images | grep payment-service
```{{exec}}

---

### 4. Quét lại toàn diện với Trivy Image

Thực thi quét phiên bản mới:

```bash
trivy image --severity HIGH,CRITICAL payment-service:v2
```{{exec}}

Quan sát kết quả: Toàn bộ các cảnh báo nghiêm trọng trong hệ điều hành của phiên bản v1 đã biến mất. 

---

### 5. Quản lý ngoại lệ bảo mật với tệp .trivyignore

Trong thực tế doanh nghiệp, có những CVE chưa có bản vá từ nhà phân phối (`Fixed Version: ""`) hoặc thuộc tính năng mà ứng dụng không kích hoạt. Đội ngũ an ninh có thể tạm thời miễn trừ bằng tệp `.trivyignore` kèm lý do phê duyệt rõ ràng:

```bash
cat << 'EOF' > .trivyignore
# Danh sach CVE ngoai le da qua danh gia an toan (Approved by SecOps)
# CVE-YYYY-XXXX: Mo ta ly do mien tru
EOF
cat .trivyignore
```{{exec}}

Nhấn **Check** để hoàn thành bước 3.
