#!/bin/bash
# background.sh — Lab 12: AWS CLI & LocalStack (VPC + Subnet + SG + EC2)

echo "Khởi tạo môi trường Cloud Lab..." > /tmp/lab-status.log

# 1. Khởi động LocalStack chạy ngầm ngay từ đầu để pull image song song (dùng v3.8 ổn định, không yêu cầu token)
echo "Đang khởi chạy LocalStack container..." > /tmp/lab-status.log
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2 \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:3.8 >/dev/null 2>&1

# 2. Giải phóng triệt để lock apt nếu Ubuntu đang chạy auto-update ngầm
echo "Đang dọn dẹp tiến trình apt hệ thống..." > /tmp/lab-status.log
systemctl stop unattended-upgrades.service apt-daily.service apt-daily-upgrade.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
killall -9 apt apt-get dpkg unattended-upgrade >/dev/null 2>&1 || true
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* /var/cache/apt/archives/lock* >/dev/null 2>&1 || true
dpkg --configure -a >/dev/null 2>&1 || true

# 3. Cài đặt các công cụ cần thiết (tối giản dependency để tải nhanh nhất)
echo "Đang cài đặt AWS CLI và các công cụ bổ trợ..." > /tmp/lab-status.log
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq --no-install-recommends awscli jq curl netcat-openbsd unzip >/dev/null 2>&1

# Fallback: nếu apt không có awscli, cài qua bản AWS CLI v2 chính thức
if ! command -v aws >/dev/null 2>&1 && [ ! -x /usr/bin/aws ]; then
  echo "Đang tải AWS CLI v2 dự phòng..." > /tmp/lab-status.log
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  python3 -c "import zipfile; zipfile.ZipFile('/tmp/awscliv2.zip').extractall('/tmp')" 2>/dev/null || unzip -q -o /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update >/dev/null 2>&1 || true
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# 4. Xác định chính xác binary gốc của aws
REAL_AWS=""
if [ -x /usr/bin/aws ]; then
  REAL_AWS="/usr/bin/aws"
elif [ -x /usr/local/aws-cli/v2/current/bin/aws ]; then
  REAL_AWS="/usr/local/aws-cli/v2/current/bin/aws"
elif [ -x /usr/local/bin/aws ] && ! grep -q "endpoint-url" /usr/local/bin/aws 2>/dev/null; then
  REAL_AWS="/usr/local/bin/aws"
elif [ -x /snap/bin/aws ]; then
  REAL_AWS="/snap/bin/aws"
elif command -v aws >/dev/null 2>&1; then
  REAL_AWS=$(which aws)
fi

# 5. Cấu hình thông số mặc định cho AWS CLI
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

# 6. Tạo wrapper an toàn cho aws và awslocal trỏ về LocalStack
if [ -n "$REAL_AWS" ] && [ -x "$REAL_AWS" ]; then
  if [ "$REAL_AWS" = "/usr/local/bin/aws" ]; then
    mv /usr/local/bin/aws /usr/local/bin/aws-bin
    REAL_AWS="/usr/local/bin/aws-bin"
  fi

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
fi

# Thiết lập biến môi trường cho tất cả bash session
cat << 'EOF' > /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

# 7. Chờ LocalStack sẵn sàng
echo "Đang chờ dịch vụ LocalStack EC2 sẵn sàng..." > /tmp/lab-status.log
MAX_RETRY=50
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
  if curl -s http://localhost:4566/_localstack/health 2>/dev/null | grep -q '"ec2": "available"\|"ec2": "running"'; then
    break
  fi
  if ! docker ps -q --filter "name=localstack" 2>/dev/null | grep -q .; then
    echo "Đang tải LocalStack Docker image (khoảng 20-35s)..." > /tmp/lab-status.log
  else
    echo "LocalStack đang khởi tạo dịch vụ EC2..." > /tmp/lab-status.log
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

# Kiểm tra đảm bảo lệnh EC2 phản hồi thành công
if [ -x /usr/local/bin/aws ]; then
  /usr/local/bin/aws ec2 describe-vpcs > /dev/null 2>&1 || true
fi

echo "Môi trường đã sẵn sàng!" > /tmp/lab-status.log
touch /tmp/.lab_ready
