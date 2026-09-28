#!/bin/bash
# background.sh — Lab 12: AWS CLI & LocalStack (VPC + Subnet + SG + EC2)

echo "Khởi tạo môi trường Cloud Lab..." > /tmp/lab-status.log

# 1. Khởi động LocalStack chạy ngầm ngay từ đầu với tag 3.8 ổn định, không yêu cầu auth token
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

# 3. Cài đặt các công cụ cơ bản
echo "Đang cài đặt các công cụ bổ trợ (curl, unzip, jq)..." > /tmp/lab-status.log
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq --no-install-recommends curl unzip jq netcat-openbsd >/dev/null 2>&1

# 4. Cài đặt AWS CLI v2 chính thức (chuẩn AWS, hỗ trợ AWS_ENDPOINT_URL gốc)
if ! command -v aws >/dev/null 2>&1; then
  echo "Đang cài đặt AWS CLI v2..." > /tmp/lab-status.log
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o /tmp/awscliv2.zip -d /tmp
  else
    python3 -c "
import zipfile, os
with zipfile.ZipFile('/tmp/awscliv2.zip', 'r') as z:
    for info in z.infolist():
        z.extract(info, '/tmp')
        mode = info.external_attr >> 16
        if mode:
            os.chmod('/tmp/' + info.filename, mode)
" 2>/dev/null
  fi
  chmod +x /tmp/aws/install /tmp/aws/dist/aws 2>/dev/null || true
  /tmp/aws/install --update >/dev/null 2>&1 || true
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Đảm bảo symlink ở cả /usr/local/bin và /usr/bin
if [ -x /usr/local/aws-cli/v2/current/bin/aws ] && [ ! -x /usr/local/bin/aws ]; then
  ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
fi
if [ -x /usr/local/bin/aws ] && [ ! -x /usr/bin/aws ]; then
  ln -sf /usr/local/bin/aws /usr/bin/aws
fi

# 5. Cấu hình thông số mặc định cho AWS CLI (Native endpoint_url)
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

# Tạo lệnh awslocal bổ trợ
cat << 'EOF' > /usr/local/bin/awslocal
#!/bin/bash
exec aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/awslocal
ln -sf /usr/local/bin/awslocal /usr/bin/awslocal 2>/dev/null || true

# Thiết lập biến môi trường hệ thống
cat << 'EOF' > /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

for rc in /root/.bashrc /home/ubuntu/.bashrc; do
  if [ -f "$rc" ] && ! grep -q "AWS_ENDPOINT_URL" "$rc"; then
    cat << 'EOF' >> "$rc"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF
  fi
done

# 6. Chờ LocalStack sẵn sàng
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
aws ec2 describe-vpcs > /dev/null 2>&1 || true

echo "Môi trường đã sẵn sàng!" > /tmp/lab-status.log
touch /tmp/.lab_ready
