# Bước 4: Đính Kèm SBOM Vào Image & Xây Dựng Deployment Gate

Bên cạnh chữ ký số, Cosign còn đóng vai trò quan trọng trong việc lưu trữ và liên kết các bằng chứng an ninh (Security Attestations / SBOM) trực tiếp vào Image Manifest trên Registry.

---

### 1. Tạo danh mục linh kiện phần mềm (SBOM) cho Image

Tạo tệp SBOM định dạng CycloneDX cho `order-service:v1.0`:

```bash
cd /root/cosign-signing-lab && trivy image --format cyclonedx -o sbom.json localhost:5000/order-service:v1.0 && ls -lh sbom.json
```{{exec}}

---

### 2. Đính kèm SBOM vào OCI Registry bằng Cosign

Sử dụng lệnh `cosign attach sbom` để đẩy tệp SBOM lên Registry và liên kết chặt chẽ với Digest của image:

```bash
cosign attach sbom --sbom sbom.json --allow-insecure-registry localhost:5000/order-service:v1.0
```{{exec}}

Kiểm tra danh mục tag trên Registry:

```bash
curl -s http://localhost:5000/v2/order-service/tags/list | jq .
```{{exec}}

Quan sát thấy xuất hiện thêm tag mới có tiền tố `sha256-...sbom`. Cả image, chữ ký số và danh mục SBOM đều được lưu trữ đồng bộ trên kho chứa OCI.

Tải lại và xác thực SBOM trực tiếp từ Registry:

```bash
cosign download sbom --allow-insecure-registry localhost:5000/order-service:v1.0 | jq '{bomFormat: .bomFormat, specVersion: .specVersion, totalComponents: (.components | length)}'
```{{exec}}

---

### 3. Xây dựng Deployment Verification Gate

Trong mô hình GitOps và Kubernetes, một cổng kiểm soát (Admission Controller hoặc Deploy Script) luôn kiểm tra chữ ký số trước khi cho phép Pod khởi chạy.

Tạo script kiểm tra tự động `verify-deployment-gate.sh`:

```bash
cat << 'EOF' > verify-deployment-gate.sh
#!/bin/bash

TARGET_IMAGE=${1:-"localhost:5000/order-service:v1.0"}
PUB_KEY="/root/cosign-signing-lab/cosign.pub"

echo "=========================================================="
echo "  [DEPLOYMENT GATE] VERIFYING IMAGE SIGNATURE VIA COSIGN  "
echo "=========================================================="
echo "Kiem tra image: $TARGET_IMAGE"

# Kiem tra chu ky so bang khoa cong khai
if cosign verify --key "$PUB_KEY" --allow-insecure-registry "$TARGET_IMAGE" > /dev/null 2>&1; then
  echo "=========================================================="
  echo "  [PASSED] Chu ky hop le! Cho phep trien khai container. "
  echo "=========================================================="
  exit 0
else
  echo "=========================================================="
  echo "  [BLOCKED] Chu ky KHONG hop le! Tu choi trien khai.     "
  echo "=========================================================="
  exit 1
fi
EOF
chmod +x verify-deployment-gate.sh
```{{exec}}

---

### 4. Kiểm thử hành vi Deployment Gate

Kiểm thử với image đã được ký hợp lệ:

```bash
./verify-deployment-gate.sh localhost:5000/order-service:v1.0
echo "Exit code: $?"
```{{exec}}

Mã thoát `0` xác nhận image đủ điều kiện an toàn để triển khai.

Kiểm thử với image giả mạo không có chữ ký:

```bash
./verify-deployment-gate.sh localhost:5000/malicious-service:v1.0 || echo "Exit code: $?"
```{{exec}}

Hệ thống trả về thông báo `[BLOCKED]` kèm mã lỗi thoát khác 0, ngăn chặn tuyệt đối nguy cơ đưa mã độc chưa được xác thực lên môi trường Production.

Nhấn **Check** để hoàn thành bài lab.
