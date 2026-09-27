#!/bin/bash
# background.sh — Lab 13: ALB + Auto Scaling Group

apt-get update -y > /dev/null 2>&1
apt-get install -y \
  python3 python3-pip \
  curl unzip jq \
  nginx docker.io \
  > /dev/null 2>&1

systemctl enable docker > /dev/null 2>&1
systemctl start docker > /dev/null 2>&1
systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1

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

docker pull nginx:alpine > /dev/null 2>&1 &

touch /tmp/.lab_ready
