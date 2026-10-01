#!/bin/bash

# Cập nhật và cài đặt công cụ cần thiết
apt-get update -y > /dev/null 2>&1
apt-get install -y tree curl > /dev/null 2>&1

# Dọn dẹp môi trường cũ nếu có
rm -f /tmp/diag-output.txt /tmp/diag-error.txt /tmp/diag-combined.txt /tmp/error-count.txt /tmp/filtered-errors.log /tmp/found-env-files.txt /tmp/leak-keys.txt > /dev/null 2>&1
rm -rf /opt/microservices /opt/diagnostic.sh /var/log/nginx > /dev/null 2>&1

# 1. Khởi tạo script chẩn đoán cho Bước 1 (phát sinh cả stdout và stderr)
cat << 'EOF' > /opt/diagnostic.sh
#!/bin/bash
echo "[OK] Database connection healthy"
echo "[ERROR] Redis cache connection refused" >&2
echo "[OK] Storage disk usage at 45%"
echo "[ERROR] SSL certificate expires in 2 days" >&2
echo "[OK] Kubernetes API Server reachable"
EOF
chmod +x /opt/diagnostic.sh

# 2. Khởi tạo log web access cho Bước 2 (chứa chính xác 12 dòng lỗi: 5 dòng lỗi 500 và 7 dòng lỗi 404)
mkdir -p /var/log/nginx
cat << 'EOF' > /var/log/nginx/access.log
192.168.1.10 - - [01/Oct/2026:10:00:01 +0700] "GET /index.html HTTP/1.1" 200 4523
192.168.1.11 - - [01/Oct/2026:10:00:02 +0700] "GET /api/v1/users HTTP/1.1" 200 1250
192.168.1.12 - - [01/Oct/2026:10:00:03 +0700] "GET /missing-page HTTP/1.1" 404 152
192.168.1.13 - - [01/Oct/2026:10:00:04 +0700] "POST /api/v1/checkout HTTP/1.1" 500 520
192.168.1.10 - - [01/Oct/2026:10:00:05 +0700] "GET /static/css/main.css HTTP/1.1" 200 8920
192.168.1.14 - - [01/Oct/2026:10:00:06 +0700] "GET /old-admin HTTP/1.1" 404 152
192.168.1.15 - - [01/Oct/2026:10:00:07 +0700] "POST /api/v1/payment HTTP/1.1" 500 480
192.168.1.16 - - [01/Oct/2026:10:00:08 +0700] "GET /products HTTP/1.1" 200 3210
192.168.1.17 - - [01/Oct/2026:10:00:09 +0700] "GET /favicon.ico HTTP/1.1" 404 152
192.168.1.18 - - [01/Oct/2026:10:00:10 +0700] "POST /api/v1/orders HTTP/1.1" 500 610
192.168.1.19 - - [01/Oct/2026:10:00:11 +0700] "GET /images/logo.png HTTP/1.1" 200 15200
192.168.1.20 - - [01/Oct/2026:10:00:12 +0700] "GET /secret HTTP/1.1" 404 152
192.168.1.21 - - [01/Oct/2026:10:00:13 +0700] "POST /api/v1/refund HTTP/1.1" 500 450
192.168.1.22 - - [01/Oct/2026:10:00:14 +0700] "GET /about-us HTTP/1.1" 200 4100
192.168.1.23 - - [01/Oct/2026:10:00:15 +0700] "GET /test-api HTTP/1.1" 404 152
192.168.1.24 - - [01/Oct/2026:10:00:16 +0700] "POST /api/v1/transact HTTP/1.1" 500 590
192.168.1.25 - - [01/Oct/2026:10:00:17 +0700] "GET /contact HTTP/1.1" 200 2300
192.168.1.26 - - [01/Oct/2026:10:00:18 +0700] "GET /docs/v1 HTTP/1.1" 404 152
192.168.1.27 - - [01/Oct/2026:10:00:19 +0700] "GET /docs/v2 HTTP/1.1" 404 152
192.168.1.28 - - [01/Oct/2026:10:00:20 +0700] "GET /healthz HTTP/1.1" 200 25
EOF

# 3. Khởi tạo cấu trúc microservices cho Bước 3
mkdir -p /opt/microservices/auth-service/configs
mkdir -p /opt/microservices/payment-service/settings
mkdir -p /opt/microservices/frontend/public
mkdir -p /opt/microservices/notification-service/scripts

cat << 'EOF' > /opt/microservices/auth-service/configs/auth.env
SERVICE_NAME=auth-service
PORT=4001
SECRET_KEY=super-secret-auth-key-999
DB_HOST=postgres.internal
EOF

cat << 'EOF' > /opt/microservices/payment-service/settings/payment.env
SERVICE_NAME=payment-service
PORT=4002
SECRET_KEY=payment-live-vault-888
GATEWAY_URL=https://gateway.bank.internal
EOF

cat << 'EOF' > /opt/microservices/frontend/public/app.js
console.log("Frontend UI loading...");
EOF

cat << 'EOF' > /opt/microservices/notification-service/scripts/notify.py
print("Notification worker active")
EOF

# Đánh dấu môi trường sẵn sàng
touch /tmp/.lab_ready
