# Bước 1: Tạo VPC và hạ tầng mạng

## Thiết lập môi trường

```bash
# Cài AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# Khởi động LocalStack
docker run -d --rm --name localstack \
  -p 4566:4566 \
  -e SERVICES=ec2,elbv2,autoscaling,cloudwatch,budgets \
  localstack/localstack:3.8

echo "Chờ LocalStack..."
until curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2"'; do
  sleep 3; printf "."
done
echo " ✅ Sẵn sàng!"

alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

---

## Lý thuyết

**VPC** là mạng ảo riêng trên Cloud — tương tự datacenter riêng.

```
CIDR 10.0.0.0/16:
  - 65,534 địa chỉ khả dụng
  - Có thể chia thành nhiều Subnet nhỏ hơn
```

**Internet Gateway (IGW)**: cổng nối VPC ra Internet — không có IGW, instances bị cô lập hoàn toàn.

**Route Table**: xác định đường đi của traffic:
- `10.0.0.0/16` → đi trong VPC
- `0.0.0.0/0` → đi qua IGW ra Internet

---

## Thực hành

### 1.1 — Tạo VPC

```bash
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-vpc}]' \
  --query 'Vpc.VpcId' --output text)

echo "VPC: $VPC_ID"
```

### 1.2 — Tạo Subnet public

```bash
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ap-southeast-1a \
  --query 'Subnet.SubnetId' --output text)

aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_ID --map-public-ip-on-launch

echo "Subnet: $SUBNET_ID"
```

### 1.3 — Tạo Internet Gateway

```bash
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "IGW: $IGW_ID → gắn vào $VPC_ID"
```

### 1.4 — Cấu hình Route Table

```bash
RTB_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' --output text)

aws ec2 create-route \
  --route-table-id $RTB_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

aws ec2 associate-route-table \
  --route-table-id $RTB_ID --subnet-id $SUBNET_ID

echo "Route Table $RTB_ID: 0.0.0.0/0 → $IGW_ID"
```

### 1.5 — Lưu biến môi trường

```bash
cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_ID=$SUBNET_ID
export IGW_ID=$IGW_ID
export RTB_ID=$RTB_ID
EOF

echo "✅ Lưu vào /tmp/lab-env.sh"
```

> Mở terminal mới → chạy `source /tmp/lab-env.sh` để khôi phục biến.

---

## Câu hỏi

1. Tại sao Subnet cần route `0.0.0.0/0 → IGW` mới là "public subnet"?
2. VPC `10.0.0.0/16`, Subnet `10.0.1.0/24` — còn bao nhiêu slot để tạo thêm Subnet?
3. Xóa IGW nhưng giữ route `0.0.0.0/0` trong Route Table — điều gì xảy ra?
