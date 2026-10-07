# Bước 3: Thiết Lập Cổng Quét Lỗ Hổng Container Image (Gate 3)

Một ứng dụng dù mã nguồn hoàn toàn sạch (Gate 1 pass) và dependencies không có lỗi (Gate 2 pass) vẫn có thể bị tấn công nếu **Base Image của hệ điều hành** (như Alpine, Ubuntu, Debian) chứa các lỗ hổng nhân Linux nghiêm trọng.

**Gate 3: Container Image Security Gate** được kích hoạt ngay sau khi Docker Image được đóng gói và đóng vai trò là "chốt chặn an ninh cuối cùng" trước khi hình ảnh được phép đẩy lên Registry hoặc triển khai ra Production.

---

## 1. Cơ Chế Quét Container Image Của Trivy

Lệnh `trivy image` sẽ bóc tách từng lớp (layer) của Docker Image để quét:
1. Các gói phần mềm hệ điều hành (OS packages: `ssl`, `glibc`, `busybox`, `curl`...).
2. Các gói thư viện ứng dụng lồng ghép bên trong container.
3. Người dùng thực thi (phát hiện nếu container chạy bằng quyền root).

---

## 2. Các Bước Thực Hiện

### 2.1 — Tạo script kiểm soát an ninh Gate 3

Tạo tệp script `gate3-image-scan.sh` tự động hóa việc build và quét image:

```bash
cd /root/security-gate-lab
cat << 'EOF' > gate3-image-scan.sh
#!/bin/bash
set -e

IMAGE_TAG="devsecops-demo:v1.0"

echo "=========================================================="
echo "[GATE 3] Tien hanh build Docker Image: $IMAGE_TAG..."
echo "=========================================================="
docker build -t "$IMAGE_TAG" .

echo ""
echo "[GATE 3] Dang quet an ninh Container Image..."
set +e
trivy image \
  --severity CRITICAL,HIGH \
  --exit-code 1 \
  --ignore-unfixed \
  --format table \
  --output /root/security-gate-lab/gate3-report.txt \
  "$IMAGE_TAG"

EXIT_STATUS=$?
if [ $EXIT_STATUS -ne 0 ]; then
  echo ""
  echo "[GATE 3 FAILED] Phat hien lo hong CVE nguy cap trong Container Image!"
  echo "Tu choi cho phep deploy len Production."
  exit 1
else
  echo ""
  echo "[GATE 3 PASSED] Container Image an toan tuyet doi. Cho phep phat hanh!"
  exit 0
fi
EOF

chmod +x gate3-image-scan.sh
```{{exec}}

---

### 2.2 — Thực thi kiểm tra Gate 3

Chạy script kiểm tra Gate 3:

```bash
./gate3-image-scan.sh
```{{exec}}

Quan sát quá trình thực thi:
1. Docker tiến hành đóng gói image `devsecops-demo:v1.0` từ base image `node:20-alpine`.
2. Trivy phân tích toàn bộ các layer và gói thư viện bên trong image.
3. Do `node:20-alpine` là base image hiện đại và đã được cập nhật bản vá bảo mật, kết quả in ra `[GATE 3 PASSED]`.

Xem nội dung báo cáo Gate 3:

```bash
cat gate3-report.txt
```{{exec}}

Kiểm tra image đã sẵn sàng triển khai trên hệ thống:

```bash
docker images devsecops-demo:v1.0
```{{exec}}

Nhấn **Check** để hoàn thành Bước 3!
