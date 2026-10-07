# Bước 3: Xác Thực Chữ Ký Số & Ngăn Chặn Tấn Công Giả Mạo

Sau khi image được ký số và lưu trữ trên Registry, bất kỳ máy chủ Production hoặc cụm Kubernetes nào cũng có thể sử dụng **Khóa công khai (cosign.pub)** để xác thực tính toàn vẹn trước khi cho phép tiến trình chạy.

---

### 1. Xác thực chữ ký số bằng Khóa công khai

Chạy lệnh xác thực chữ ký đối với image `order-service:v1.0`:

```bash
cd /root/cosign-signing-lab && cosign verify --key cosign.pub --allow-insecure-registry localhost:5000/order-service:v1.0
```{{exec}}

Thông báo xác nhận thành công hiển thị trên terminal:
```
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
```

---

### 2. Phân tích cấu trúc chứng nhận Claims

Trích xuất dữ liệu chứng chỉ an ninh được nhúng trong chữ ký số:

```bash
cosign verify --key cosign.pub --allow-insecure-registry localhost:5000/order-service:v1.0 | jq '.[0]'
```{{exec}}

Quan sát cấu trúc payload JSON:
* **critical.identity.docker-reference**: Địa chỉ kho lưu trữ của image.
* **critical.image.docker-manifest-digest**: Mã băm bất biến của image tại thời điểm được ký.
* **critical.type**: Loại chữ ký tiêu chuẩn `cosign container image signature`.

---

### 3. Mô phỏng cuộc tấn công đánh tráo Image (Tampering Attack)

Giả sử kẻ tấn công đã giành được quyền truy cập vào Registry và đẩy một container giả mạo chưa được kiểm duyệt lên hệ thống với tên `malicious-service:v1.0`:

```bash
docker tag alpine:latest localhost:5000/malicious-service:v1.0 && docker push localhost:5000/malicious-service:v1.0
```{{exec}}

Bây giờ, mô phỏng cơ chế kiểm soát của máy chủ Production hoặc Kubernetes Admission Controller bằng cách chạy lệnh xác thực trên image này:

```bash
cosign verify --key cosign.pub --allow-insecure-registry localhost:5000/malicious-service:v1.0
```{{exec}}

Quan sát lỗi trả về từ Cosign:
```
Error: no matching signatures: no matching signatures found
```

Kiểm tra mã thoát lỗi của lệnh:

```bash
echo "Exit code: $?"
```{{exec}}

Mã thoát khác `0` (lỗi) chứng minh rằng Cosign đã chặn đứng hoàn toàn image giả mạo. Dù kẻ tấn công có cố tình đặt tên giống nhau hay đánh tráo tag, việc không sở hữu Private Key để tạo chữ ký mật mã hợp lệ sẽ khiến image độc hại bị vô hiệu hóa ngay từ vòng ngoài.

Nhấn **Check** để hoàn thành bước 3.
