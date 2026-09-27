# Bước 1: Tạo VPC và hạ tầng mạng cơ bản

## Thiết lập môi trường (chạy một lần)

Trước khi bắt đầu, cài AWS CLI và khởi động LocalStack:

```bash
# Cài AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# Khởi động LocalStack qua Docker (community, miễn phí)
docker run -d --rm --name localstack \
  -p 4566:4566 \
  -e SERVICES=ec2,elbv2,autoscaling,cloudwatch,budgets \
  localstack/localstack:3.8

# Chờ LocalStack sẵn sàng (~30-60 giây)
echo "Đang chờ LocalStack..."
until curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2"'; do
  sleep 3; printf "."
done
echo " ✅ LocalStack sẵn sàng!"

# Tạo alias: aws → gọi LocalStack thay vì AWS thật
alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

---

## Lý thuyết

**VPC (Virtual Private Cloud)** là mạng ảo riêng của bạn trên Cloud — tương tự như một datacenter riêng trong môi trường ảo hóa.

```
CIDR 10.0.0.0/16 nghĩa là:
  - Network ID  : 10.0.0.0
  - Broadcast   : 10.0.255.255
  - Địa chỉ khả dụng: 65,534 hosts
  - Có thể chia thành nhiều Subnet nhỏ hơn
```

**Internet Gateway (IGW)** là cổng kết nối giữa VPC và Internet. Không có IGW, các instance trong VPC sẽ hoàn toàn bị cô lập.

**Route Table** xác định "đường đi" cho traffic:
- Traffic nội bộ VPC (`10.0.0.0/16`) → đi trong VPC
- Traffic ra ngoài (`0.0.0.0/0`) → đi qua Internet Gateway

---

## Thử thách thực hành

### 1.1 — Tạo VPC

Tạo VPC với CIDR block `10.0.0.0/16` và gắn tag tên `devops-vpc`:

```bash
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-vpc},{Key=Project,Value=devops-training}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC đã tạo: $VPC_ID"
```

Kiểm tra VPC vừa tạo:

```bash
aws ec2 describe-vpcs \
  --vpc-ids $VPC_ID \
  --query 'Vpcs[0].{ID:VpcId,CIDR:CidrBlock,State:State}' \
  --output table
```

---

### 1.2 — Tạo Subnet public

Tạo Subnet với CIDR `10.0.1.0/24` (256 địa chỉ, trong đó 251 dùng được):

```bash
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ap-southeast-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1a}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Subnet đã tạo: $SUBNET_ID"
```

Bật tự động gán Public IP cho mọi instance khởi động trong subnet này:

```bash
aws ec2 modify-subnet-attribute \
  --subnet-id $SUBNET_ID \
  --map-public-ip-on-launch
```

---

### 1.3 — Tạo Internet Gateway

```bash
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=devops-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

# Gắn IGW vào VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

echo "Internet Gateway $IGW_ID đã gắn vào VPC $VPC_ID"
```

---

### 1.4 — Cấu hình Route Table

```bash
# Lấy Route Table mặc định của VPC
RTB_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

# Thêm route: traffic ra Internet đi qua IGW
aws ec2 create-route \
  --route-table-id $RTB_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Gắn Route Table vào Subnet
aws ec2 associate-route-table \
  --route-table-id $RTB_ID \
  --subnet-id $SUBNET_ID

echo "Route Table đã cấu hình:"
aws ec2 describe-route-tables \
  --route-table-ids $RTB_ID \
  --query 'RouteTables[0].Routes[*].{Destination:DestinationCidrBlock,Target:GatewayId}' \
  --output table
```

---

### 1.5 — Lưu biến môi trường

Lưu các ID vào file để dùng ở các bước sau:

```bash
cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_ID=$SUBNET_ID
export IGW_ID=$IGW_ID
export RTB_ID=$RTB_ID
EOF

echo "✅ Đã lưu biến vào /tmp/lab-env.sh"
cat /tmp/lab-env.sh
```

> 💡 Nếu mở terminal mới, chạy `source /tmp/lab-env.sh` để khôi phục biến.

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao Subnet cần phải được gắn với một Route Table có route `0.0.0.0/0 → IGW` thì mới gọi là "public subnet"?
2. Nếu CIDR của VPC là `10.0.0.0/16` và Subnet là `10.0.1.0/24`, còn bao nhiêu "slot" để tạo thêm Subnet?
3. Điều gì xảy ra nếu xóa Internet Gateway nhưng không xóa route `0.0.0.0/0` trong Route Table?
