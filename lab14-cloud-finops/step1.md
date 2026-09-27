# Bước 1: Gắn Cost Allocation Tags lên tài nguyên Cloud

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
