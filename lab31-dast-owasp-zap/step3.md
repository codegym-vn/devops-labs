# Bước 3: Phân Tích Báo Cáo Rủi Ro & Cơ Chế Khai Thác

Báo cáo do OWASP ZAP tạo ra cung cấp đầy đủ thông tin: Mã định danh quy tắc (Plugin ID), Mức độ rủi ro (Risk), Mã lỗ hổng chuẩn quốc tế (CWE ID) và Giải pháp kỹ thuật khuyến nghị (Solution).

---

### 1. Trích xuất danh sách lỗ hổng và giải pháp từ báo cáo JSON

Sử dụng `jq` để lọc các thông số kỹ thuật cốt lõi:

```bash
cd /root/dast-target-app
jq '.site[0].alerts[] | {name: .name, risk: .risk, cweid: .cweid, solution: .solution}' zap-initial-report.json
```

---

### 2. Phân tích chi tiết 4 mối đe dọa an ninh DAST

| Plugin ID | Tên lỗ hổng | Mức độ | CWE ID | Cơ chế tấn công & Khắc phục |
|---|---|---|---|---|
| **10020** | Anti-clickjacking Header Not Set | Medium | CWE-1021 | Kẻ tấn công tạo một trang web độc hại nhúng trang đăng nhập vào iframe trong suốt, lừa người dùng nhấn nhầm nút chuyển tiền hoặc đổi mật khẩu. **Cách sửa:** Thêm `X-Frame-Options: SAMEORIGIN`. |
| **10038** | CSP Header Not Set | Medium | CWE-693 | Trình duyệt không biết nguồn nạp script nào là hợp lệ, tạo điều kiện cho mã độc XSS thực thi tự do. **Cách sửa:** Thêm tiêu đề `Content-Security-Policy: default-src 'self'`. |
| **10021** | X-Content-Type-Options Missing | Low | CWE-16 | Trình duyệt cố gắng tự đoán định dạng (MIME-sniffing), có thể thực thi tệp ảnh tải lên như tệp mã JavaScript. **Cách sửa:** Thêm `X-Content-Type-Options: nosniff`. |
| **10004** | Server Leaks X-Powered-By | Low | CWE-200 | Tiết lộ framework Express, giúp tin tặc thu hẹp phạm vi tấn công theo phiên bản. **Cách sửa:** Loại bỏ header bằng `app.disable('x-powered-by')`. |

---

### 3. Tạo kế hoạch khắc phục an ninh (Remediation Plan)

Trích xuất danh sách tên các lỗ hổng cần xử lý vào tệp `remediation-plan.txt`:

```bash
jq -r '.site[0].alerts[].name' zap-initial-report.json > remediation-plan.txt
cat remediation-plan.txt
```

Nhấn **Check** để hoàn thành bước 3!
