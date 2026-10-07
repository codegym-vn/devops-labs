# Bước 2: Đóng Gói, Đẩy Image Lên Registry & Thực Thi Ký Số

Sau khi chuẩn bị cặp khóa mật mã, chúng ta sẽ đóng gói ứng dụng `order-service`, đẩy lên kho lưu trữ OCI và sử dụng khóa bí mật để ký số chứng thực bản phát hành.

---

### 1. Đóng gói Docker Image dịch vụ Order Service

Xây dựng image với tiền tố địa chỉ của Registry cục bộ:

```bash
cd /root/cosign-signing-lab && docker build -t localhost:5000/order-service:v1.0 .
```{{exec}}

---

### 2. Đẩy Image lên Registry cục bộ

Đẩy image vừa build lên kho lưu trữ trên cổng 5000:

```bash
docker push localhost:5000/order-service:v1.0
```{{exec}}

Tra cứu mã băm bất biến (RepoDigest) của Image:

```bash
docker inspect --format='{{index .RepoDigests 0}}' localhost:5000/order-service:v1.0
```{{exec}}

Trong mô hình an ninh chuỗi cung ứng:
* **Image Tag (`:v1.0`):** Có tính chất biến đổi (Mutable). Bất kỳ ai có quyền ghi đều có thể đẩy một image khác đè lên cùng tên tag đó.
* **Image Digest (`sha256:...`):** Có tính chất bất biến (Immutable). Mã băm đại diện cho đúng nội dung các layer và manifest. Cosign luôn tính toán và ký số dựa trên mã băm Digest này.

---

### 3. Thực thi ký số bằng Cosign

Ký số lên Image bằng khóa bí mật `cosign.key`. Sử dụng cờ `--allow-insecure-registry` vì Registry thử nghiệm đang chạy qua HTTP nội bộ:

```bash
COSIGN_PASSWORD="SecureCosignPass123" cosign sign --key cosign.key --allow-insecure-registry -y localhost:5000/order-service:v1.0
```{{exec}}

Thông báo trả về trên terminal:
```
Pushing signature to: localhost:5000/order-service
```

---

### 4. Khám phá OCI Signature Artifact trên Registry

Cosign không can thiệp vào các layer hay làm thay đổi kích thước của image gốc. Thay vào đó, Cosign tạo ra một đối tượng OCI Artifact riêng biệt chứa chữ ký và đẩy thẳng lên Registry.

Kiểm tra danh mục tag của kho lưu trữ `order-service`:

```bash
curl -s http://localhost:5000/v2/order-service/tags/list | jq .
```{{exec}}

Quan sát danh sách tag trả về:
* Tag phát hành: `v1.0`
* Tag chữ ký số: Có tiền tố `sha256-...sig`

Chữ ký số đã được gắn chặt với mã băm của image `v1.0` ngay trên kho lưu trữ đám mây.

Nhấn **Check** để hoàn thành bước 2.
