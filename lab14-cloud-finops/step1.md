# Bước 1: Gắn Cost Allocation Tags lên tài nguyên Cloud

## Thiết lập môi trường (chạy một lần)

```bash
# Cài AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# Cài LocalStack
pip3 install -q --break-system-packages localstack

# Khởi động LocalStack
localstack start -d

echo "Đang chờ LocalStack..."
until curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2": "available"'; do
  sleep 3; printf "."
done
echo " ✅ LocalStack sẵn sàng!"

alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Tạo 5 EC2 instances mô phỏng (dùng cho gắn tag)
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --query 'Vpc.VpcId' --output text)
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
SG_ID=$(aws ec2 create-security-group \
  --group-name lab-sg --description "Lab SG" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)

TYPES=("t3.large" "t3.medium" "t3.large" "t3.xlarge" "t3.medium")
INST_IDS=()
for i in 0 1 2 3 4; do
  ID=$(aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 \
    --instance-type ${TYPES[$i]} --subnet-id $SUBNET_ID \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' --output text)
  INST_IDS+=($ID)
done

cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_ID=$SUBNET_ID
export SG_ID=$SG_ID
export INST_0=${INST_IDS[0]}
export INST_1=${INST_IDS[1]}
export INST_2=${INST_IDS[2]}
export INST_3=${INST_IDS[3]}
export INST_4=${INST_IDS[4]}
EOF

source /tmp/lab-env.sh
echo "✅ 5 EC2 instances sẵn sàng để gắn tag"
```

> 📋 Dataset CUR và script phân tích đã có sẵn trong `/opt/lab-data/`

---

## Lý thuyết

**Cost Allocation Tags** là metadata gắn lên tài nguyên Cloud giúp phân bổ chi phí theo nhiều chiều:

| Tag | Mục đích |
|-----|---------|
| `Project` | Chi phí theo dự án/sản phẩm |
| `Environment` | production vs staging vs dev |
| `Owner` | Team chịu trách nhiệm |
| `CostCenter` | Phòng ban thanh toán |

> ⚠️ Tags phải được gắn **trước** khi tài nguyên tạo ra chi phí. Tags sau này không áp dụng ngược cho chi phí đã phát sinh.

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 1.1 — Xem tài nguyên chưa có tag

```bash
echo "=== EC2 instances chưa có tag Project ==="
aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,Tags:Tags}" \
  --output table
```

### 1.2 — Gắn Tags lên từng instance theo vai trò

```bash
# API server production
aws ec2 create-tags --resources $INST_0 --tags \
  Key=Name,Value=api-server-prod \
  Key=Project,Value=e-commerce \
  Key=Environment,Value=production \
  Key=Owner,Value=team-backend \
  Key=CostCenter,Value=engineering

# Web server production
aws ec2 create-tags --resources $INST_1 --tags \
  Key=Name,Value=web-server-prod \
  Key=Project,Value=e-commerce \
  Key=Environment,Value=production \
  Key=Owner,Value=team-frontend \
  Key=CostCenter,Value=engineering

# Worker production
aws ec2 create-tags --resources $INST_2 --tags \
  Key=Name,Value=worker-prod \
  Key=Project,Value=data-platform \
  Key=Environment,Value=production \
  Key=Owner,Value=team-data \
  Key=CostCenter,Value=data

# Reporting server (underutilized)
aws ec2 create-tags --resources $INST_3 --tags \
  Key=Name,Value=reporting-server \
  Key=Project,Value=internal-tools \
  Key=Environment,Value=production \
  Key=Owner,Value=team-devops \
  Key=CostCenter,Value=operations

# Old test server (should be terminated)
aws ec2 create-tags --resources $INST_4 --tags \
  Key=Name,Value=old-test-server \
  Key=Project,Value=internal-tools \
  Key=Environment,Value=development \
  Key=Owner,Value=team-devops \
  Key=CostCenter,Value=operations

echo "✅ Đã gắn Tags cho 5 instances"
```

### 1.3 — Gắn Tags lên VPC và Subnet

```bash
aws ec2 create-tags --resources $VPC_ID --tags \
  Key=Name,Value=main-vpc \
  Key=Project,Value=e-commerce \
  Key=Environment,Value=production

aws ec2 create-tags --resources $SUBNET_ID --tags \
  Key=Name,Value=public-subnet \
  Key=Project,Value=e-commerce

echo "✅ Đã gắn Tags cho VPC và Subnet"
```

### 1.4 — Kiểm tra Tags đã gắn đúng

```bash
echo "=== Xem Tags của tất cả instances ==="
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,Project:Tags[?Key==`Project`]|[0].Value,Env:Tags[?Key==`Environment`]|[0].Value}' \
  --output table
```

### 1.5 — Tìm tài nguyên chưa gắn tag (Tag Compliance Check)

```bash
echo "=== Kiểm tra compliance: tài nguyên thiếu tag Project ==="
aws ec2 describe-instances \
  --query "Reservations[*].Instances[?!Tags[?Key=='Project']].{ID:InstanceId,Type:InstanceType}" \
  --output table

UNTAGGED=$(aws ec2 describe-instances \
  --query "length(Reservations[*].Instances[?!Tags[?Key=='Project']][]) | [0]" \
  --output text)
echo "Số instance thiếu tag Project: $UNTAGGED (mục tiêu: 0)"
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao cần gắn tag `CostCenter` thay vì chỉ dùng `Project`?
2. Nếu một resource không có tag `Environment`, chi phí của nó sẽ xuất hiện như thế nào trong Cost Explorer?
3. Làm thế nào để **tự động gắn tag** cho mọi resource mới tạo? (gợi ý: AWS Config Rules, Tag Policies)
