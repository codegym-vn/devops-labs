#!/bin/bash
# background.sh — Lab 12: AWS CLI & LocalStack (VPC + Subnet + SG + EC2)

# 1. Cài đặt các công cụ cần thiết
apt-get update -y > /dev/null 2>&1
apt-get install -y awscli jq curl netcat-openbsd > /dev/null 2>&1

# 2. Khởi động LocalStack hỗ trợ dịch vụ EC2 trên port 4566
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2 \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:latest > /dev/null 2>&1

# 3. Cấu hình thông số mặc định cho AWS CLI
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set default.region us-east-1
aws configure set default.output json

# 4. Tạo wrapper script cho aws và awslocal trỏ tự động về LocalStack
cat << 'EOF' > /usr/local/bin/awslocal
#!/bin/bash
/usr/bin/aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/awslocal

cat << 'EOF' > /usr/local/bin/aws
#!/bin/bash
/usr/bin/aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/aws

# Thiết lập biến môi trường cho tất cả bash session
cat << 'EOF' >> /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

# 5. Chờ LocalStack sẵn sàng
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
