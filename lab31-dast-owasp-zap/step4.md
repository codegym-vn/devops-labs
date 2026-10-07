# Bước 4: Khắc Phục Lỗ Hổng Bằng Helmet.js & Quét Nghiệm Thu An Toàn

Để khắc phục đồng thời cả 4 vấn đề an ninh tiêu đề HTTP mà OWASP ZAP đã cảnh báo, giải pháp chuẩn mực trong hệ sinh thái Node.js là tích hợp thư viện **Helmet.js**.

Helmet là middleware tập trung thiết lập 15 tiêu đề HTTP bảo mật tự động, bao gồm CSP, HSTS, X-Frame-Options, X-Content-Type-Options và tự động gỡ bỏ `X-Powered-By`.

---

### 1. Cập nhật mã nguồn ứng dụng với Helmet.js

Mở tệp `server.js` và bổ sung middleware `helmet()` ngay sau khi khởi tạo đối tượng Express `app`:

```bash
cd /root/dast-target-app

cat << 'EOF' > server.js
const express = require('express');
const helmet = require('helmet');

const app = express();
const PORT = 3000;

// Kích hoạt toàn bộ bộ lá chắn bảo mật HTTP Headers của Helmet
app.use(helmet());

// Tắt hoàn toàn tiêu đề tiết lộ phiên bản máy chủ
app.disable('x-powered-by');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Trang chu voi form dang nhap
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Portal Noi Bo - DevSecOps Demo</title>
  <style>
    body { font-family: sans-serif; margin: 40px; background: #f4f6f8; }
    .card { background: white; padding: 24px; border-radius: 8px; max-width: 400px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    input { width: 100%; padding: 8px; margin: 8px 0 16px; box-sizing: border-box; }
    button { background: #0066cc; color: white; border: none; padding: 10px 16px; border-radius: 4px; cursor: pointer; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Dang Nhap He Thong</h2>
    <form action="/login" method="POST">
      <label>Ten dang nhap:</label>
      <input type="text" name="username" required>
      <label>Mat khau:</label>
      <input type="password" name="password" required>
      <button type="submit">Xac Nhan</button>
    </form>
  </div>
</body>
</html>
  `);
});

// Endpoint API suc khoe
app.get('/api/health', (req, res) => {
  res.json({ status: 'UP', timestamp: new Date().toISOString() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Target Web Application (Secured) dang chay tren cong ${PORT}`);
});
EOF
```

---

### 2. Khởi động lại ứng dụng và kiểm tra tiêu đề HTTP

Tắt tiến trình cũ và khởi chạy phiên bản đã được bảo vệ:

```bash
pkill -f "node server.js" || true
sleep 1
nohup node server.js > app.log 2>&1 &
sleep 2
```

Kiểm tra lại Response Headers của ứng dụng:

```bash
curl -I http://localhost:3000
```

Quan sát các tiêu đề an ninh mới xuất hiện:
```http
HTTP/1.1 200 OK
Content-Security-Policy: default-src 'self';base-uri 'self';font-src 'self' https: data:;form-action 'self';frame-ancestors 'self';img-src 'self' data:;object-src 'none';script-src 'self';script-src-attr 'none';style-src 'self' https: 'unsafe-inline';upgrade-insecure-requests
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Origin-Agent-Cluster: ?1
Referrer-Policy: no-referrer
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-DNS-Prefetch-Control: off
X-Download-Options: noopen
X-Frame-Options: SAMEORIGIN
X-Permitted-Cross-Domain-Policies: none
X-XSS-Protection: 0
```
> Tiêu đề `X-Powered-By` đã biến mất hoàn toàn, và các cơ chế chống Clickjacking, CSP, MIME-sniffing đã hoạt động.

---

### 3. Thực thi quét nghiệm thu DAST với OWASP ZAP

Chạy lại OWASP ZAP Baseline Scan để nghiệm thu:

```bash
zap-baseline.py -t http://localhost:3000 -J zap-final-report.json -r zap-final-report.html
```

Quan sát thông báo nghiệm thu an ninh từ ZAP:
```
------------------------------------------------------------
PASS: 1	WARN: 0	FAIL: 0	SKIP: 0
------------------------------------------------------------

[ZAP SCAN FINISHED] Hoan thanh quet DAST khong phat hien canh bao moi!
```

Kiểm tra số lượng cảnh báo trong tệp nghiệm thu JSON:

```bash
jq '.site[0].alerts | length' zap-final-report.json
```

Kết quả trả về `0` và mã thoát (exit code) là `0`. Toàn bộ ứng dụng đã đáp ứng các tiêu chuẩn an ninh động (DAST) sẵn sàng phát hành lên Production!

Nhấn **Check** để hoàn thành bài lab!
