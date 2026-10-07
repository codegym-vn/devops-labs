# Bước 2: Thực Thi Quét Động DAST Với OWASP ZAP Baseline Scan

**OWASP ZAP Baseline Scan** là chế độ quét thụ động (Passive Scan) được thiết kế đặc biệt cho các CI/CD pipeline. Chế độ này không gửi các payload phá hoại hay làm sập ứng dụng, mà phân tích toàn diện các thông điệp HTTP Request và Response để tìm kiếm các sai phạm cấu hình an ninh thời gian thực.

---

### 1. Kích hoạt OWASP ZAP Baseline Scan

Thực thi lệnh quét nhắm vào ứng dụng đang chạy tại `http://localhost:3000`, đồng thời xuất báo cáo dưới cả hai định dạng JSON (`-J`) và HTML (`-r`):

```bash
cd /root/dast-target-app
zap-baseline.py -t http://localhost:3000 -J zap-initial-report.json -r zap-initial-report.html -w
```

> **Giải thích tham số:**
> * `-t`: Chỉ định URL mục tiêu cần quét.
> * `-J`: Đường dẫn xuất báo cáo chi tiết định dạng JSON cho máy tính và CI pipeline xử lý.
> * `-r`: Đường dẫn xuất báo cáo giao diện HTML trực quan.
> * `-w`: Chế độ cảnh báo (Warning Mode) cho phép ghi nhận toàn bộ lỗ hổng mà không ngắt kịch bản.

---

### 2. Quan sát kết quả phân tích trên Terminal

Quan sát các cảnh báo được ZAP phát hiện:
```
WARN-NEW: Anti-clickjacking Header (X-Frame-Options) Not Set [10020] x 1 (http://localhost:3000) - Risk: Medium
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 1 (http://localhost:3000) - Risk: Medium
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1 (http://localhost:3000) - Risk: Low
WARN-NEW: Server Leaks Information via 'X-Powered-By' HTTP Response Header Field [10004] x 1 (http://localhost:3000) - Risk: Low
```

Kiểm tra số lượng cảnh báo được ghi lại trong tệp báo cáo JSON:

```bash
jq '.site[0].alerts | length' zap-initial-report.json
```

Kết quả hiển thị `4` cảnh báo lỗ hổng an ninh động.

Nhấn **Check** để hoàn thành bước 2!
