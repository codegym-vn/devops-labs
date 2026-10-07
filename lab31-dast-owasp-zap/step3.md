# Bước 3: Phân Tích Báo Cáo Rủi Ro & Cơ Chế Khai Thác

Báo cáo ZAP cung cấp cho mỗi cảnh báo: mã plugin (`pluginid`), mức độ rủi ro (`riskdesc`), mã CWE (`cweid`) và giải pháp (`solution`).

---

### 1. Trích xuất danh sách cảnh báo từ báo cáo JSON

```bash
cd /root/dast-target-app && jq -r '.site[0].alerts[] | "\(.pluginid)\t\(.riskdesc)\tCWE-\(.cweid)\t\(.name)"' zap-reports/zap-initial-report.json
```{{exec}}

Xem giải pháp ZAP đề xuất cho từng cảnh báo:

```bash
jq -r '.site[0].alerts[] | "[\(.pluginid)] \(.name)\n  Giai phap: \(.solution | gsub("<[^>]*>"; ""))\n"' zap-reports/zap-initial-report.json
```{{exec}}

---

### 2. Phân tích 4 cảnh báo chính về HTTP Header

| Plugin ID | Tên cảnh báo | Mức độ | CWE | Cơ chế tấn công và cách sửa |
|---|---|---|---|---|
| **10020** | Missing Anti-clickjacking Header | Medium | 1021 | Kẻ tấn công nhúng trang vào iframe trong suốt, lừa người dùng bấm nhầm nút. Sửa bằng `X-Frame-Options: SAMEORIGIN` hoặc CSP `frame-ancestors 'self'`. |
| **10038** | Content Security Policy Header Not Set | Medium | 693 | Không có danh sách nguồn script hợp lệ, mã độc XSS chạy tự do. Sửa bằng header `Content-Security-Policy`. |
| **10021** | X-Content-Type-Options Header Missing | Low | 693 | Trình duyệt tự đoán kiểu MIME, có thể thực thi tệp tải lên như JavaScript. Sửa bằng `X-Content-Type-Options: nosniff`. |
| **10037** | Server Leaks Information via X-Powered-By | Low | 200 | Lộ framework Express, giúp kẻ tấn công thu hẹp phạm vi tìm lỗ hổng. Sửa bằng cách gỡ header `X-Powered-By`. |

Ngoài 4 cảnh báo trên, ZAP có thể báo thêm các mục như **Permissions Policy Header Not Set (10063)** hoặc **Absence of Anti-CSRF Tokens (10202)** cho form đăng nhập. Đây là các điểm cần cải thiện thêm sau bài lab.

---

### 3. Lập kế hoạch khắc phục

Ghi danh sách cảnh báo vào tệp `remediation-plan.txt`:

```bash
jq -r '.site[0].alerts[] | "\(.pluginid) | \(.riskdesc) | \(.name)"' zap-reports/zap-initial-report.json > remediation-plan.txt && cat remediation-plan.txt
```{{exec}}

Nhấn **Check** để hoàn thành bước 3.
