# Bước 2: Thiết Lập Cổng Quét Lỗ Hổng Thư Viện Phụ Thuộc SCA (Gate 2)

Hơn 80% mã nguồn trong các ứng dụng hiện đại cấu thành từ các thư viện mã nguồn mở của bên thứ ba (npm, pip, maven...). Các lỗ hổng đã công bố (Common Vulnerabilities and Exposures - CVE) trong các gói này là con đường phổ biến nhất để hacker chiếm quyền điều khiển máy chủ.

Cổng **Gate 2: Software Composition Analysis (SCA)** sử dụng công cụ **Trivy** quét toàn bộ cây thư mục tệp tin (`trivy fs`) để đối soát các thư viện với cơ sở dữ liệu lỗ hổng bảo mật toàn cầu.

---

## 1. Cơ Chế Ngưỡng Chặn Của Trivy

Trivy hỗ trợ hai tham số cốt lõi để xây dựng Security Gate:
* `--severity CRITICAL,HIGH`: Chỉ lọc các lỗ hổng ở mức độ Nguy cấp và Cao. Bỏ qua các cảnh báo Low/Medium để tránh làm nghẽn tiến độ phát triển.
* `--exit-code 1`: Nếu phát hiện bất kỳ CVE nào thuộc mức độ trên, Trivy sẽ trả về mã thoát `1` (thay vì 0) để báo hiệu cho pipeline biết cần phải dừng lại.
* `--ignore-unfixed`: Bỏ qua các lỗ hổng chưa có bản vá từ nhà phát triển để tránh chặn oan lập trình viên.

---

## 2. Các Bước Thực Hiện

### 2.1 — Tạo script kiểm soát an ninh Gate 2

Tạo tệp script `gate2-sca-scan.sh`:

```bash
cd /root/security-gate-lab
cat << 'EOF' > gate2-sca-scan.sh
#!/bin/bash
echo "=========================================================="
echo "[GATE 2] Dang quet lo hong dependencies SCA voi Trivy..."
echo "=========================================================="

trivy fs \
  --severity CRITICAL,HIGH \
  --exit-code 1 \
  --ignore-unfixed \
  --format table \
  --output /root/security-gate-lab/gate2-report.txt \
  .

if [ $? -ne 0 ]; then
  echo ""
  echo "[GATE 2 FAILED] Phat hien lo hong CVE muc do CRITICAL/HIGH trong dependencies!"
  echo "Tu choi cho phep dong goi container."
  exit 1
else
  echo "[GATE 2 PASSED] Khong co lo hong nguy cap trong thu vien. Cho phep di tiep."
  exit 0
fi
EOF

chmod +x gate2-sca-scan.sh
```{{exec}}

---

### 2.2 — Thực thi kiểm tra Gate 2

Chạy script kiểm soát Gate 2:

```bash
./gate2-sca-scan.sh
```{{exec}}

Quan sát kết quả:
* Trivy phân tích tệp `package.json` và cơ sở dữ liệu các gói Node.js.
* Gói `express: ^4.19.2` là phiên bản an toàn đã vá các lỗi bảo mật đã biết.
* Kết quả trả về `[GATE 2 PASSED]`, cấp phép cho pipeline chuyển sang giai đoạn đóng gói Docker.

Xem báo cáo chi tiết:

```bash
cat gate2-report.txt
```{{exec}}

Nhấn **Check** để hoàn thành Bước 2!
