# Bước 1: Khởi Tạo Ứng Dụng Mẫu & Cổng Quét Secret Leak (Gate 1)

Cổng an ninh đầu tiên trong pipeline DevSecOps là **Secret Scanning Gate**. Mục tiêu là kiểm tra xem có bất kỳ mật khẩu, khóa API hoặc token xác thực nào bị vô tình đưa vào mã nguồn hay không. Nếu có, pipeline phải lập tức dừng lại (Fail-Fast).

---

## 1. Kiểm Tra Mã Nguồn Ban Đầu

Di chuyển vào thư mục làm việc:

```bash
cd /root/security-gate-lab
ls -la
```{{exec}}

Kiểm tra nội dung các tệp cơ bản:
* `server.js`: Mã nguồn dịch vụ Node.js Express.
* `package.json`: Khai báo phụ thuộc.
* `Dockerfile`: Đóng gói ứng dụng đa tầng.

---

## 2. Thiết Lập & Kiểm Tra Gate 1 Với Gitleaks

Thực hiện chạy Gitleaks kiểm tra toàn bộ kho lưu trữ:

```bash
gitleaks detect --source . -v
```{{exec}}

Kiểm tra mã thoát (Exit code) của lệnh:

```bash
echo "Exit code: $?"
```{{exec}}

Kết quả in ra `Exit code: 0`, chứng minh mã nguồn hiện tại đang an toàn tuyệt đối và Gate 1 mở cho phép pipeline đi tiếp.

---

## 3. Tạo Script Kiểm Soát Cổng An Ninh Gate 1

Tạo tệp script `gate1-secret-scan.sh` đóng vai trò bước kiểm soát tự động:

```bash
cat << 'EOF' > gate1-secret-scan.sh
#!/bin/bash
echo "=========================================================="
echo "[GATE 1] Dang quet ro ri thong tin mat voi Gitleaks..."
echo "=========================================================="

gitleaks detect --source . -v --report-path /root/security-gate-lab/gate1-report.json

if [ $? -ne 0 ]; then
  echo ""
  echo "[GATE 1 FAILED] Phat hien thong tin mat trong ma nguon!"
  echo "Tu choi cho phep pipeline tiep tuc."
  exit 1
else
  echo "[GATE 1 PASSED] Khong phat hien secret leaker. Cho phep di tiep."
  exit 0
fi
EOF

chmod +x gate1-secret-scan.sh
```{{exec}}

Thực thi kiểm tra script:

```bash
./gate1-secret-scan.sh
```{{exec}}

Kết quả trả về `[GATE 1 PASSED]` với mã thoát 0.

Nhấn **Check** để hoàn thành Bước 1!
