#!/bin/bash
# background.sh — Lab 13: ALB + Auto Scaling Group
set -e
LOG="/var/log/lab-init.log"
exec > "$LOG" 2>&1

echo "[$(date)] Khởi tạo môi trường Lab 13..."

apt-get update -q
apt-get install -y -q python3 python3-pip curl unzip jq nginx docker.io wrk netcat-openbsd

systemctl enable docker && systemctl start docker
systemctl enable nginx && systemctl start nginx

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# LocalStack
pip3 install -q localstack localstack-client

# AWS credentials giả cho LocalStack
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

# Alias + env
cat >> /root/.bashrc << 'EOF'
alias aws="aws --endpoint-url=http://localhost:4566"
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
EOF

# Khởi động LocalStack
LOCALSTACK_VOLUME_DIR=/var/lib/localstack localstack start -d

# Chờ LocalStack sẵn sàng
for i in $(seq 1 60); do
  if curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2": "available"'; then
    echo "[$(date)] LocalStack sẵn sàng"
    break
  fi
  sleep 2
done

# Kéo Docker image
docker pull nginx:alpine -q

# Tạo VPC nền tảng từ Lab 12 (học viên dùng lại)
export AWS_DEFAULT_REGION=ap-southeast-1
BASE_URL="--endpoint-url=http://localhost:4566"

VPC_ID=$(aws $BASE_URL ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-vpc}]' \
  --query 'Vpc.VpcId' --output text)

SUBNET_1=$(aws $BASE_URL ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --availability-zone ap-southeast-1a \
  --query 'Subnet.SubnetId' --output text)

SUBNET_2=$(aws $BASE_URL ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 --availability-zone ap-southeast-1b \
  --query 'Subnet.SubnetId' --output text)

IGW_ID=$(aws $BASE_URL ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws $BASE_URL ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

RTB_ID=$(aws $BASE_URL ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' --output text)
aws $BASE_URL ec2 create-route --route-table-id $RTB_ID \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

SG_ID=$(aws $BASE_URL ec2 create-security-group \
  --group-name alb-sg --description "ALB + ASG Security Group" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)
aws $BASE_URL ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws $BASE_URL ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Lưu biến
cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_1=$SUBNET_1
export SUBNET_2=$SUBNET_2
export IGW_ID=$IGW_ID
export SG_ID=$SG_ID
EOF

# Script lab-status
cat > /usr/local/bin/lab-status << 'SCRIPT'
#!/bin/bash
echo "=== Trạng thái Lab 13 ==="
curl -sf http://localhost:4566/_localstack/health >/dev/null 2>&1 \
  && echo "✅ LocalStack : đang chạy" || echo "❌ LocalStack : lỗi"
docker ps >/dev/null 2>&1 \
  && echo "✅ Docker     : đang chạy" || echo "❌ Docker     : lỗi"
nginx -t >/dev/null 2>&1 \
  && echo "✅ Nginx      : đang chạy" || echo "❌ Nginx      : lỗi"
CONTAINERS=$(docker ps --filter "name=app-" --format "{{.Names}}" | wc -l)
echo "   Backend containers: $CONTAINERS"
SCRIPT
chmod +x /usr/local/bin/lab-status

echo "[$(date)] ✅ Môi trường Lab 13 sẵn sàng"
touch /tmp/lab-ready
