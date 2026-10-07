# Bước 4: Thiết Lập Container Security Gate Trong CI/CD & Xuất SBOM

Trong quy trình DevSecOps tự động, việc kiểm tra an ninh Container Image phải được thiết lập thành một Security Gate nghiêm ngặt trước khi đẩy (push) image lên Container Registry (Docker Hub, AWS ECR, Harbor). Nếu image chứa lỗ hổng nguy hiểm, pipeline CI/CD sẽ lập tức bị chặn lại.

---

### 1. Xây dựng Container Security Gate Script

Tạo script kiểm tra tự động `container-security-gate.sh`:

```bash
cd /root/container-security-lab
cat << 'EOF' > container-security-gate.sh
#!/bin/bash
set -e

IMAGE_NAME=${1:-"payment-service:v2"}

echo "=========================================================="
echo "  [SECURITY GATE] RUNNING CONTAINER IMAGE AUDIT VIA TRIVY "
echo "=========================================================="
echo "Target Image: $IMAGE_NAME"

# Chan pipeline (tra ve exit code 1) neu phat hien CVE muc HIGH hoac CRITICAL
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  --format table \
  "$IMAGE_NAME"

echo "=========================================================="
echo "  [PASSED] Container image $IMAGE_NAME dat chuan an toan! "
echo "=========================================================="
EOF
chmod +x container-security-gate.sh
```{{exec}}

Giải thích tham số:
* `--exit-code 1`: Yêu cầu Trivy trả về mã thoát lỗi 1 nếu phát hiện bất kỳ vi phạm nào, giúp CI runner tự động dừng tiến trình đóng gói.
* `--ignore-unfixed`: Bỏ qua các lỗ hổng chưa có bản vá chính thức từ nhà phân phối OS nhằm tránh làm nghẽn pipeline do các lỗi ngoài tầm kiểm soát của đội ngũ phát triển.

---

### 2. Kiểm thử hành vi của Security Gate

Thực thi kiểm tra với image an toàn `payment-service:v2`:

```bash
./container-security-gate.sh payment-service:v2
echo "Exit code: $?"
```{{exec}}

Mã thoát `0` xác nhận Image v2 đã vượt qua cổng kiểm soát an ninh thành công.

Thử nghiệm kiểm tra với image cũ `payment-service:v1` để chứng minh cơ chế tự động chặn của Security Gate:

```bash
./container-security-gate.sh payment-service:v1 || echo "Security Gate da chan dung thanh cong image v1 kem ma loi exit code: $?"
```{{exec}}

---

### 3. Xuất danh mục thành phần phần mềm (SBOM) của Container

Trivy hỗ trợ bóc tách toàn bộ gói hệ điều hành và thư viện runtime để tạo danh mục kiểm kê phần mềm toàn diện (Software Bill of Materials) theo định dạng chuẩn **CycloneDX**:

```bash
trivy image --format cyclonedx -o container-sbom.json payment-service:v2
ls -lh container-sbom.json
```{{exec}}

---

### 4. Khảo sát dữ liệu kiểm toán SBOM bằng jq

Đọc thông tin cấu trúc SBOM và tổng số linh kiện phần mềm được đóng gói bên trong Container:

```bash
jq '{bomFormat: .bomFormat, specVersion: .specVersion, totalComponents: (.components | length)}' container-sbom.json
```{{exec}}

Trích xuất danh sách 15 linh kiện phần mềm đầu tiên kèm theo phân loại thành phần:

```bash
jq -r '.components[] | "\(.name)@\(.version) [\(.type)]"' container-sbom.json | head -n 15
```{{exec}}

Tệp `container-sbom.json` đóng vai trò là chứng thực số về nguồn gốc xuất xứ của container, phục vụ công tác kiểm toán và giám sát chuỗi cung ứng phần mềm Cloud Native.

Nhấn **Check** để hoàn thành bài lab.
