#!/bin/bash
# background.sh — Lab 12: Cloud VPC + VM + Security Groups
# Chỉ cài các package nhẹ, KHÔNG cài LocalStack/AWS CLI ở đây

apt-get update -y > /dev/null 2>&1
apt-get install -y \
  python3 python3-pip \
  curl unzip jq \
  docker.io \
  > /dev/null 2>&1

systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1

# Cấu hình AWS credentials giả (dùng sau khi học viên cài AWS CLI)
mkdir -p /root/.aws
cat > /root/.aws/credentials << 'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF
cat > /root/.aws/config << 'EOF'
[default]
region = ap-southeast-1
output = json
EOF

# Kéo sẵn nginx image (nhỏ, ~40MB) để bước sau không chờ
docker pull nginx:alpine > /dev/null 2>&1 &

touch /tmp/.lab_ready
