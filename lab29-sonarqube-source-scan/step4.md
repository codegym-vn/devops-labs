# Bước 4: Phân Tích Chỉ Số Đo Lường & Thiết Lập Cổng Quality Gate

Sau khi SonarScanner gửi báo cáo, tiến trình **Compute Engine (CE)** của SonarQube xử lý báo cáo **bất đồng bộ**, phân loại phát hiện thành Bugs, Vulnerabilities, Security Hotspots, Code Smells và đối chiếu với **Quality Gate**.

---

### 1. Chờ Compute Engine xử lý xong báo cáo

Nếu truy vấn kết quả ngay sau khi scan, dữ liệu có thể chưa sẵn sàng. Đọc `ceTaskId` từ `report-task.txt` và chờ tác vụ đạt trạng thái `SUCCESS`:

```bash
cd /root/sonarqube-lab && TASK_ID=$(grep ceTaskId .scannerwork/report-task.txt | cut -d= -f2); until [ "$(curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/ce/task?id=$TASK_ID" | jq -r '.task.status')" = "SUCCESS" ]; do echo "Compute Engine dang xu ly bao cao... Cho 3s"; sleep 3; done; echo "Bao cao da xu ly xong"
```{{exec}}

---

### 2. Truy vấn các vấn đề được phát hiện qua API

```bash
curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/issues/search?componentKeys=express-api-service" | jq '{total: .total, issues: [.issues[] | {rule: .rule, severity: .severity, message: .message, line: .line}]}'
```{{exec}}

SonarQube chỉ ra các dòng mã có vấn đề trong `src/app.py`, ví dụ:
* Rule `python:S1481`: biến `unused_variable` khai báo nhưng không sử dụng.
* Rule `python:S125`: đoạn mã bị comment lại thay vì xóa bỏ.

---

### 3. Kiểm tra trạng thái Quality Gate

Dự án mặc định áp dụng Quality Gate **Sonar way**:

```bash
curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/qualitygates/project_status?projectKey=express-api-service" | jq .projectStatus
```{{exec}}

Các điều kiện của **Sonar way** áp dụng cho **New Code**. Ở lần phân tích đầu tiên, toàn bộ mã được coi là baseline nên trạng thái thường là `OK`. Từ các lần phân tích sau, nếu mã mới có Vulnerability, Bug, hoặc độ phủ test dưới 80%, trạng thái sẽ chuyển sang `ERROR`.

---

### 4. Viết script tự động kiểm tra Quality Gate cho CI/CD

Pipeline CI/CD cần một bước tự động dừng build khi Quality Gate bị vi phạm:

```bash
cat << 'EOF' > /root/sonarqube-lab/check-quality-gate.sh
#!/bin/bash
PROJECT_KEY="express-api-service"
SONAR_URL="http://localhost:9000"
TOKEN=$(cat /root/sonarqube-lab/sonar-token.txt)

echo ">>> [CI GATE] Kiem tra Quality Gate cho du an $PROJECT_KEY..."

STATUS=$(curl -s -u "$TOKEN:" "$SONAR_URL/api/qualitygates/project_status?projectKey=$PROJECT_KEY" | jq -r '.projectStatus.status // empty')

if [ -z "$STATUS" ]; then
  echo "[CI GATE ERROR] Khong lay duoc trang thai tu SonarQube"
  exit 1
fi

echo ">>> Ket qua Quality Gate: $STATUS"

if [ "$STATUS" = "OK" ]; then
  echo ">>> [GATE PASSED] Du an dat tieu chuan chat luong ma nguon"
  exit 0
else
  echo ">>> [GATE FAILED] Du an vi pham Quality Gate. Chan pipeline"
  exit 1
fi
EOF
chmod +x /root/sonarqube-lab/check-quality-gate.sh
```{{exec}}

Chạy script:

```bash
/root/sonarqube-lab/check-quality-gate.sh; echo "Exit code: $?"
```{{exec}}

Kết quả `[GATE PASSED]` với `Exit code: 0` báo hiệu pipeline được phép đi tiếp sang bước đóng gói.

Nhấn **Check** để hoàn thành bước 4.
