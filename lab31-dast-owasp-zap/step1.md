# Bước 1: Khởi Chạy Ứng Dụng Web Mục Tiêu & Khảo Sát Bề Mặt Tấn Công

DAST kiểm thử ứng dụng **đang chạy**, nên trước tiên cần khởi động ứng dụng mục tiêu để công cụ quét có thể gửi HTTP request tới.

---

### 1. Cài đặt Node.js và jq

Cài Node.js 18 dạng binary (thư viện Helmet 7 yêu cầu Node.js 16 trở lên) và `jq` để đọc báo cáo JSON:

```bash
curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.gz | tar -xz -C /opt && ln -sf /opt/node-v18.20.4-linux-x64/bin/node /usr/local/bin/node && ln -sf /opt/node-v18.20.4-linux-x64/bin/npm /usr/local/bin/npm && node -v && npm -v
```{{exec}}

```bash
apt-get update -qq && apt-get install -y -qq jq > /dev/null && echo "Da cai xong jq"
```{{exec}}

---

### 2. Cài thư viện và khởi chạy ứng dụng

```bash
cd /root/dast-target-app && npm install --no-audit --no-fund
```{{exec}}

Khởi chạy ứng dụng ở chế độ nền trên cổng 3000:

```bash
nohup node server.js > app.log 2>&1 & sleep 2; curl -s http://localhost:3000/api/health | jq .
```{{exec}}

Kiểm tra tiến trình đang lắng nghe:

```bash
ss -tlnp | grep 3000
```{{exec}}

---

### 3. Khảo sát bề mặt tấn công qua HTTP Response Headers

Kẻ tấn công hoặc công cụ DAST luôn bắt đầu bằng việc quan sát header phản hồi của máy chủ:

```bash
curl -I http://localhost:3000
```{{exec}}

Kết quả:
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: ...
```

Các điểm yếu quan sát được:
1. **Rò rỉ công nghệ:** `X-Powered-By: Express` cho kẻ tấn công biết framework backend để tìm lỗ hổng tương ứng.
2. **Thiếu chống Clickjacking:** không có `X-Frame-Options` hoặc CSP `frame-ancestors`, trang có thể bị nhúng vào iframe ẩn trên trang độc hại.
3. **Thiếu Content Security Policy:** trình duyệt không có danh sách nguồn script hợp lệ, tăng tác hại khi bị XSS.
4. **Thiếu chống MIME Sniffing:** không có `X-Content-Type-Options: nosniff`.

Nhấn **Check** để hoàn thành bước 1.
