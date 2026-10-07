# Bước 4: Phân Tích Chỉ Số Đo Lường & Thiết Lập Cổng Quality Gate

Sau khi SonarScanner gửi báo cáo lên server, tiến trình **Compute Engine (CE)** của SonarQube phân loại các phát hiện thành Bugs, Vulnerabilities, Security Hotspots và Code Smells, đồng thời đối chiếu với chính sách **Quality Gate (Cổng chất lượng)**.

---

### 1. Truy vấn các vấn đề (Issues) được phát hiện qua API

SonarQube cung cấp hệ thống REST API hoàn chỉnh để các công cụ bên ngoài có thể trích xuất báo cáo. Hãy truy vấn danh sách lỗi tìm thấy trong dự án:

```bash
curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/issues/search?componentKeys=express-api-service" | jq '{total: .total, issues: [.issues[] | {rule: .rule, severity: .severity, message: .message, line: .line}]}'
```

Bạn sẽ thấy SonarQube chỉ ra chính xác các dòng mã có vấn đề trong `src/app.js`:
* Biến không sử dụng (`unusedVariable`).
* Thông tin nhạy cảm dạng comment hoặc các điểm cần tối ưu hóa.

---

### 2. Kiểm tra trạng thái Cổng chất lượng (Quality Gate)

Mặc định, dự án được áp dụng bộ quy chuẩn **Sonar way**. Truy vấn trạng thái cổng chất lượng của dự án:

```bash
curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/qualitygates/project_status?projectKey=express-api-service" | jq .projectStatus
```

Phản hồi trả về cấu trúc:
```json
{
  "status": "OK",
  "conditions": [ ... ]
}
```
Nếu mã nguồn mới vi phạm các điều kiện (ví dụ: Security Rating kém hơn A, Coverage dưới 80%, hoặc có Vulnerability chưa xử lý), trường `status` sẽ chuyển sang `ERROR`.

---

### 3. Viết script tự động hóa kiểm tra Quality Gate trong CI/CD

Trong thực tế, pipeline CI/CD (GitHub Actions, GitLab CI, Jenkins) cần một tập lệnh kiểm tra để tự động dừng build nếu Quality Gate bị vi phạm.

Tạo tệp `/root/sonarqube-lab/check-quality-gate.sh`:

```bash
cat << 'EOF' > /root/sonarqube-lab/check-quality-gate.sh
#!/bin/bash
set -e

PROJECT_KEY="express-api-service"
SONAR_URL="http://localhost:9000"
TOKEN=$(cat /root/sonarqube-lab/sonar-token.txt 2>/dev/null || true)

echo ">>> [CI GATE] Dang kiem tra trang thai Quality Gate cho du an $PROJECT_KEY..."

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
  AUTH_HEADER="-u $TOKEN:"
else
  AUTH_HEADER="-u admin:AdminSecurePass123"
fi

STATUS=$(curl -s $AUTH_HEADER "$SONAR_URL/api/qualitygates/project_status?projectKey=$PROJECT_KEY" | jq -r '.projectStatus.status // empty')

if [ -z "$STATUS" ]; then
  echo "[CI GATE ERROR] Khong the lay du lieu trang thai tu SonarQube!"
  exit 1
fi

echo ">>> Ket qua Quality Gate: $STATUS"

if [ "$STATUS" = "OK" ]; then
  echo ">>> [GATE PASSED] Du an vuot qua tieu chuan an ninh & chat luong ma nguon!"
  exit 0
else
  echo ">>> [GATE FAILED] Du an vi pham Cổng chất lượng SonarQube! Chan pipeline."
  exit 1
fi
EOF

chmod +x /root/sonarqube-lab/check-quality-gate.sh
```

Thực thi kiểm tra cổng chất lượng:

```bash
/root/sonarqube-lab/check-quality-gate.sh
```

Kết quả trả về `[GATE PASSED]` và mã thoát (exit code) là `0`, báo hiệu pipeline được phép tiếp tục bước đóng gói container.

Nhấn **Check** để hoàn thành bước 4!
