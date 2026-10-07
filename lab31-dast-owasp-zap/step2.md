# Bước 2: Thực Thi Quét Động DAST Với OWASP ZAP Baseline Scan

**ZAP Baseline Scan** là chế độ quét thụ động (Passive Scan) dành cho CI/CD. ZAP chạy spider khoảng 1 phút để thu thập các URL, sau đó phân tích request và response tìm sai sót cấu hình bảo mật. Chế độ này **không gửi payload tấn công** nên an toàn khi chạy với môi trường staging.

---

### 1. Kéo Docker image OWASP ZAP

Image chính thức của ZAP có dung lượng lớn, khoảng 1.5 đến 2GB. Quá trình tải có thể mất vài phút:

```bash
docker pull ghcr.io/zaproxy/zaproxy:stable
```{{exec}}

---

### 2. Chạy ZAP Baseline Scan

```bash
cd /root/dast-target-app && docker run --rm --network host -v /root/dast-target-app/zap-reports:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://localhost:3000 -J zap-initial-report.json -r zap-initial-report.html -I; echo "Exit code: $?"
```{{exec}}

Giải thích tham số:
* `--network host`: container dùng chung mạng với máy chủ để truy cập `localhost:3000`.
* `-v .../zap-reports:/zap/wrk`: ZAP ghi báo cáo vào `/zap/wrk`, được ánh xạ ra thư mục `zap-reports` trên máy chủ.
* `-t`: URL mục tiêu.
* `-J` và `-r`: xuất báo cáo dạng JSON và HTML.
* `-I`: không trả về mã lỗi khi chỉ có cảnh báo mức WARN, phù hợp lần quét khảo sát đầu tiên.

Mã thoát của `zap-baseline.py` khi không dùng `-I`: `0` là không có cảnh báo, `1` là có FAIL, `2` là có WARN. Pipeline CI dựa vào mã này để quyết định chặn hay cho qua.

---

### 3. Quan sát kết quả

Phần tổng kết cuối cùng có dạng:
```
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 2
WARN-NEW: Server Leaks Information via "X-Powered-By" HTTP Response Header Field(s) [10037] x 2
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 1
...
FAIL-NEW: 0  FAIL-INPROG: 0  WARN-NEW: ...  WARN-INPROG: 0  INFO: 0  IGNORE: 0  PASS: ...
```

Số lượng cảnh báo chính xác phụ thuộc phiên bản ZAP. Mỗi cảnh báo gồm tên, mã plugin trong ngoặc vuông và số URL bị ảnh hưởng.

Kiểm tra các tệp báo cáo:

```bash
ls -la zap-reports/ && jq '.site[0].alerts | length' zap-reports/zap-initial-report.json
```{{exec}}

Nhấn **Check** để hoàn thành bước 2.
