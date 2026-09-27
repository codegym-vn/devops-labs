# Bước 1: Gắn Cost Allocation Tags

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

# Tạo 5 EC2 instances để thực hành gắn tag
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
SG_ID=$(aws ec2 create-security-group \
  --group-name lab-sg --description "Lab SG" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)

TYPES=("t3.large" "t3.medium" "t3.large" "t3.xlarge" "t3.medium")
NAMES=("api-server-prod" "web-server-prod" "worker-prod" "reporting-server" "old-test-server")
INST_IDS=()
for i in 0 1 2 3 4; do
  ID=$(aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type ${TYPES[$i]} \
    --subnet-id $SUBNET_ID \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' --output text)
  INST_IDS+=($ID)
  echo "Instance ${NAMES[$i]}: $ID"
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
echo "✅ 5 instances sẵn sàng"
```

> Dataset `/opt/lab-data/` đã được tạo sẵn bởi background script.

---

## Lý thuyết

**Cost Allocation Tags**: metadata gắn lên tài nguyên giúp phân bổ chi phí theo nhiều chiều.

| Tag | Mục đích |
|-----|---------|
| `Name` | Tên tài nguyên |
| `Project` | Phân bổ chi phí theo dự án |
| `Environment` | production / staging / dev |
| `Owner` | Team chịu trách nhiệm |
| `CostCenter` | Mã trung tâm chi phí |

---

## Thực hành

### 1.1 — Gắn tags cho 5 instances

```bash
source /tmp/lab-env.sh

# Instance 0: api-server-prod
aws ec2 create-tags --resources $INST_0 --tags \
  Key=Name,Value=api-server-prod \
  Key=Project,Value=e-commerce \
  Key=Environment,Value=production \
  Key=Owner,Value=team-backend \
  Key=CostCenter,Value=CC-001

# Instance 1: web-server-prod
aws ec2 create-tags --resources $INST_1 --tags \
  Key=Name,Value=web-server-prod \
  Key=Project,Value=e-commerce \
  Key=Environment,Value=production \
  Key=Owner,Value=team-frontend \
  Key=CostCenter,Value=CC-001

# Instance 2: worker-prod
aws ec2 create-tags --resources $INST_2 --tags \
  Key=Name,Value=worker-prod \
  Key=Project,Value=data-platform \
  Key=Environment,Value=production \
  Key=Owner,Value=team-data \
  Key=CostCenter,Value=CC-002

# Instance 3: reporting-server
aws ec2 create-tags --resources $INST_3 --tags \
  Key=Name,Value=reporting-server \
  Key=Project,Value=internal-tools \
  Key=Environment,Value=staging \
  Key=Owner,Value=team-devops \
  Key=CostCenter,Value=CC-003

# Instance 4: old-test-server (thiếu tag — mục đích kiểm tra compliance)
aws ec2 create-tags --resources $INST_4 --tags \
  Key=Name,Value=old-test-server
```

### 1.2 — Kiểm tra tag compliance

```bash
echo "=== Instances THIẾU tag Project ==="
for ID in $INST_0 $INST_1 $INST_2 $INST_3 $INST_4; do
  HAS_TAG=$(aws ec2 describe-tags \
    --filters "Name=resource-id,Values=$ID" "Name=key,Values=Project" \
    --query 'length(Tags)' --output text)
  NAME=$(aws ec2 describe-tags \
    --filters "Name=resource-id,Values=$ID" "Name=key,Values=Name" \
    --query 'Tags[0].Value' --output text)
  [ "$HAS_TAG" = "0" ] && echo "  ❌ $ID ($NAME) — thiếu tag Project" || echo "  ✅ $ID ($NAME)"
done
```

### 1.3 — Gắn tag bổ sung cho instance thiếu

```bash
aws ec2 create-tags --resources $INST_4 --tags \
  Key=Project,Value=internal-tools \
  Key=Environment,Value=development \
  Key=Owner,Value=team-devops \
  Key=CostCenter,Value=CC-003

echo "✅ old-test-server đã đủ tag"
```

---

## Câu hỏi

1. Tại sao `Environment` tag lại quan trọng khi phân tích chi phí?
2. Chiến lược nào đảm bảo **tag consistency** khi team scale lên 50 engineers?
3. Nếu dùng Terraform, làm sao tự động gắn tag cho mọi resource?
