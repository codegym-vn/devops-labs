# Bước 4: Khắc Phục Lỗ Hổng Bằng Helmet.js & Quét Nghiệm Thu

**Helmet** là middleware cho Express, tự động thiết lập nhóm HTTP Security Header gồm CSP, HSTS, X-Frame-Options, X-Content-Type-Options và gỡ bỏ `X-Powered-By`.

---

### 1. Tích hợp Helmet vào ứng dụng

Thêm `require('helmet')` và `app.use(helmet())` ngay sau khi khởi tạo `app`:

```bash
cd /root/dast-target-app
python3 - << 'EOF'
p = "server.js"
s = open(p).read()
s = s.replace("const express = require('express');\n",
              "const express = require('express');\nconst helmet = require('helmet');\n", 1)
s = s.replace("const PORT = 3000;\n",
              "const PORT = 3000;\n\n// Bat bo HTTP Security Headers cua Helmet\napp.use(helmet());\n", 1)
open(p, "w").write(s)
print("Da tich hop Helmet")
EOF
head -n 10 server.js
```{{exec}}

---

### 2. Khởi động lại ứng dụng và kiểm tra header

```bash
pkill -f "node server.js"; sleep 1; nohup node server.js > app.log 2>&1 & sleep 2; curl -I http://localhost:3000
```{{exec}}

Các header bảo mật mới xuất hiện:
```http
Content-Security-Policy: default-src 'self';base-uri 'self';font-src 'self' https: data:;form-action 'self';frame-ancestors 'self';...
Strict-Transport-Security: max-age=15552000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
...
```
Header `X-Powered-By` đã biến mất.

---

### 3. Quét nghiệm thu với OWASP ZAP

```bash
docker run --rm --network host -v /root/dast-target-app/zap-reports:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://localhost:3000 -J zap-final-report.json -r zap-final-report.html -I; echo "Exit code: $?"
```{{exec}}

So sánh danh sách mã plugin trước và sau khi sửa:

```bash
echo "TRUOC:" $(jq -r '[.site[0].alerts[].pluginid] | sort | join(" ")' zap-reports/zap-initial-report.json); echo "SAU:  " $(jq -r '[.site[0].alerts[].pluginid] | sort | join(" ")' zap-reports/zap-final-report.json)
```{{exec}}

Kiểm tra riêng 4 cảnh báo đã xử lý:

```bash
for id in 10020 10021 10037 10038; do if jq -e --arg id "$id" '.site[0].alerts[] | select(.pluginid == $id)' zap-reports/zap-final-report.json > /dev/null; then echo "$id: VAN CON"; else echo "$id: DA KHAC PHUC"; fi; done
```{{exec}}

Cả 4 mã `10020`, `10021`, `10037`, `10038` đều báo **DA KHAC PHUC**.

Báo cáo sau có thể vẫn còn một số cảnh báo mới, ví dụ **CSP: style-src unsafe-inline (10055)** do cấu hình CSP mặc định của Helmet, hoặc **Permissions Policy Header Not Set (10063)**. Trên thực tế, mỗi lần quét DAST thường giúp tìm ra điểm cần siết chặt tiếp. Đây là quá trình cải thiện liên tục, không phải kiểm tra một lần.

Nhấn **Check** để hoàn thành bài lab.
