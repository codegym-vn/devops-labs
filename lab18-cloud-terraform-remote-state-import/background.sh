#!/bin/bash
# background.sh — Lab 18: Remote Backend, State Recovery & Infrastructure Import

echo "Khởi tạo môi trường Terraform Remote Backend & Import..." > /tmp/lab-status.log

# 1. Khởi chạy LocalStack container (hỗ trợ EC2, STS, S3, DynamoDB)
echo "Đang khởi chạy LocalStack container..." > /tmp/lab-status.log
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2,sts,s3,dynamodb \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:3.8 >/dev/null 2>&1

# 2. Giải phóng lock apt hệ thống
echo "Đang dọn dẹp tiến trình apt..." > /tmp/lab-status.log
systemctl stop unattended-upgrades.service apt-daily.service apt-daily-upgrade.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
killall -9 apt apt-get dpkg unattended-upgrade >/dev/null 2>&1 || true
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* /var/cache/apt/archives/lock* >/dev/null 2>&1 || true
dpkg --configure -a >/dev/null 2>&1 || true

# 3. Cài đặt các công cụ bổ trợ
echo "Đang cài đặt các công cụ cơ bản (curl, unzip, jq)..." > /tmp/lab-status.log
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq --no-install-recommends curl unzip jq netcat-openbsd >/dev/null 2>&1

# 4. Cài đặt Terraform CLI chính thức (v1.9.5)
if ! command -v terraform >/dev/null 2>&1; then
  echo "Đang cài đặt Terraform CLI v1.9.5..." > /tmp/lab-status.log
  curl -sSL "https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip" -o "/tmp/terraform.zip"
  unzip -q -o /tmp/terraform.zip -d /usr/local/bin/
  chmod +x /usr/local/bin/terraform
  ln -sf /usr/local/bin/terraform /usr/bin/terraform
  rm -f /tmp/terraform.zip
fi

# 5. Cài đặt AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  echo "Đang cài đặt AWS CLI v2..." > /tmp/lab-status.log
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  chmod +x /tmp/aws/install /tmp/aws/dist/aws 2>/dev/null || true
  /tmp/aws/install --update >/dev/null 2>&1 || true
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws 2>/dev/null || true
ln -sf /usr/local/bin/aws /usr/bin/aws 2>/dev/null || true

# 6. Cấu hình thông số mặc định cho AWS CLI & Biến môi trường
mkdir -p /root/.aws /home/ubuntu/.aws 2>/dev/null

cat << 'EOF' > /root/.aws/config
[default]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
EOF

cat << 'EOF' > /root/.aws/credentials
[default]
aws_access_key_id = mock_access_key
aws_secret_access_key = mock_secret_key
EOF

cp -r /root/.aws /home/ubuntu/ 2>/dev/null || true
chown -R ubuntu:ubuntu /home/ubuntu/.aws 2>/dev/null || true

cat << 'EOF' > /usr/local/bin/awslocal
#!/bin/bash
exec aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/awslocal
ln -sf /usr/local/bin/awslocal /usr/bin/awslocal 2>/dev/null || true

# 7. Cấu hình bộ nhớ đệm Plugin Cache cho Terraform
echo "Đang cấu hình Terraform Plugin Cache..." > /tmp/lab-status.log
mkdir -p /var/cache/terraform-plugins /root/.terraform.d/plugin-cache /home/ubuntu/.terraform.d/plugin-cache
chmod 777 /var/cache/terraform-plugins

cat << 'EOF' > /root/.terraformrc
plugin_cache_dir = "/var/cache/terraform-plugins"
EOF
cp /root/.terraformrc /home/ubuntu/.terraformrc
chown -R ubuntu:ubuntu /home/ubuntu/.terraformrc /home/ubuntu/.terraform.d 2>/dev/null || true

# 8. Tải trước AWS Provider Plugin vào cache
echo "Đang tải trước AWS Provider Plugin vào cache..." > /tmp/lab-status.log
mkdir -p /tmp/tf-prewarm
cat << 'EOF' > /tmp/tf-prewarm/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    ec2      = "http://localhost:4566"
    sts      = "http://localhost:4566"
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}
EOF
(cd /tmp/tf-prewarm && terraform init >/dev/null 2>&1)
rm -rf /tmp/tf-prewarm

# 9. Chuẩn bị thư mục dự án chính
mkdir -p /root/terraform-remote-lab /home/ubuntu/terraform-remote-lab
chown -R ubuntu:ubuntu /home/ubuntu/terraform-remote-lab 2>/dev/null || true

# 10. Chờ LocalStack sẵn sàng các dịch vụ cốt lõi
echo "Đang kiểm tra kết nối dịch vụ LocalStack (EC2, S3, DynamoDB)..." > /tmp/lab-status.log
MAX_RETRY=50
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
  HEALTH=$(curl -s http://localhost:4566/_localstack/health 2>/dev/null)
  if echo "$HEALTH" | grep -q '"ec2": "available"\|"ec2": "running"' && \
     echo "$HEALTH" | grep -q '"s3": "available"\|"s3": "running"' && \
     echo "$HEALTH" | grep -q '"dynamodb": "available"\|"dynamodb": "running"'; then
    break
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

echo "Môi trường Terraform Remote Backend & Import đã sẵn sàng!" > /tmp/lab-status.log
touch /tmp/.lab_ready
