#!/bin/bash

# Cập nhật và cài đặt công cụ cần thiết
apt-get update -y > /dev/null 2>&1
apt-get install -y tree curl > /dev/null 2>&1

# 1. Khởi tạo môi trường cho Bước 1
mkdir -p /opt/audit
cat << 'EOF' > /opt/audit/company_secrets.txt
CONFIDENTIAL - INTERNAL USE ONLY
Database Password: SecretPassword123
API Token: live_token_987654321
EOF
chmod 640 /opt/audit/company_secrets.txt

# 2. Khởi tạo môi trường cho Bước 2
mkdir -p /opt/secure-service
cat << 'EOF' > /opt/secure-service/deploy.sh
#!/bin/bash
echo "Deploying application service..."
EOF
cat << 'EOF' > /opt/secure-service/config.env
APP_ENV=production
APP_PORT=8080
EOF
cat << 'EOF' > /opt/secure-service/service.key
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC3
-----END PRIVATE KEY-----
EOF
# Gán quyền ban đầu chưa chuẩn để học viên thực hành sửa lại
chmod 777 /opt/secure-service/deploy.sh
chmod 777 /opt/secure-service/config.env
chmod 777 /opt/secure-service/service.key

# 3. Khởi tạo môi trường cho Bước 3
# Tạo group developers và user webapps nếu chưa tồn tại
if ! getent group developers > /dev/null 2>&1; then
    groupadd developers
fi

if ! id -u webapps > /dev/null 2>&1; then
    useradd -m -s /bin/bash -g developers webapps
fi

mkdir -p /opt/web-service/logs
cat << 'EOF' > /opt/web-service/index.html
<!DOCTYPE html>
<html>
<head><title>Web Service</title></head>
<body><h1>Hello from Production Web Service</h1></body>
</html>
EOF

# Để quyền sở hữu ban đầu thuộc về root
chown -R root:root /opt/web-service
chmod -R 700 /opt/web-service

# Đánh dấu môi trường đã sẵn sàng
touch /tmp/.lab_ready
