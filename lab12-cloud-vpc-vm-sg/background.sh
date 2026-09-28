#!/bin/bash
# background.sh — Lab 12: AWS CLI & LocalStack (VPC + Subnet + SG + EC2)

# 1. Chờ giải phóng lock apt nếu hệ thống đang update ngầm
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 1
done

# 2. Cài đặt các công cụ cần thiết
apt-get update -y > /dev/null 2>&1
apt-get install -y awscli jq curl netcat-openbsd unzip > /dev/null 2>&1

# 3. Đảm bảo AWS CLI nhị phân tồn tại (nếu apt không có thì cài AWS CLI v2 chính thức)
if [ ! -x /usr/bin/aws ] && [ ! -x /usr/local/aws-cli/v2/current/bin/aws ]; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update > /dev/null 2>&1
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# 4. Xác định chính xác đường dẫn binary thật của aws
REAL_AWS=""
if [ -x /usr/local/aws-cli/v2/current/bin/aws ]; then
  REAL_AWS="/usr/local/aws-cli/v2/current/bin/aws"
elif [ -x /usr/bin/aws ]; then
  REAL_AWS="/usr/bin/aws"
elif [ -x /snap/bin/aws ]; then
  REAL_AWS="/snap/bin/aws"
else
  REAL_AWS=$(which aws 2>/dev/null || echo "/usr/bin/aws")
fi

# 5. Khởi động LocalStack hỗ trợ dịch vụ EC2 trên port 4566
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2 \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:latest > /dev/null 2>&1

# 6. Cấu hình thông số mặc định cho AWS CLI
mkdir -p /root/.aws /home/ubuntu/.aws 2>/dev/null

cat << 'EOF' > /root/.aws/config
[default]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
EOF

cat << 'EOF' > /root/.aws/credentials
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

cp -r /root/.aws /home/ubuntu/ 2>/dev/null || true
chown -R ubuntu:ubuntu /home/ubuntu/.aws 2>/dev/null || true

# 7. Tạo wrapper an toàn cho aws và awslocal trỏ về LocalStack
cat << EOF > /usr/local/bin/aws
#!/bin/bash
exec "$REAL_AWS" --endpoint-url=http://localhost:4566 "\$@"
EOF
chmod +x /usr/local/bin/aws

cat << EOF > /usr/local/bin/awslocal
#!/bin/bash
exec "$REAL_AWS" --endpoint-url=http://localhost:4566 "\$@"
EOF
chmod +x /usr/local/bin/awslocal

# Thiết lập biến môi trường cho tất cả bash session
cat << 'EOF' > /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

# 8. Chờ LocalStack sẵn sàng
MAX_RETRY=30
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
  if curl -s http://localhost:4566/_localstack/health | grep -q '"ec2": "available"\|"ec2": "running"'; then
    break
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

# Đảm bảo lệnh EC2 phản hồi thành công
/usr/local/bin/aws ec2 describe-vpcs > /dev/null 2>&1

# Tạo file tín hiệu sẵn sàng
touch /tmp/.lab_ready
