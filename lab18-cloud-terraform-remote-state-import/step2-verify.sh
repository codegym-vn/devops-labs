#!/bin/bash
# step2-verify.sh — Lab 18: Kiểm tra xử lý khóa và can thiệp State (force-unlock, mv, rm)

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ] || ([ "$3" = "nonempty" ] && [ -n "$2" ]); then
    echo "   $1"; PASS=$((PASS+1))
  else
    echo "   $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 2: Kiểm Tra Can Thiệp State (force-unlock, mv, rm) ==="
echo ""

WORK_DIR="/root/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra khóa mock-lock-9999 đã được giải phóng
HAS_LOCK=$(aws dynamodb get-item \
  --table-name devops-tfstate-locks \
  --key '{"LockID": {"S": "devops-tfstate-bucket/network/terraform.tfstate-md5"}}' \
  --query "Item.Info.S" \
  --output text 2>/dev/null)

LOCK_CLEARED="yes"
if echo "$HAS_LOCK" | grep -q "mock-lock-9999"; then
  LOCK_CLEARED="no"
fi

check "Khóa kẹt 'mock-lock-9999' đã được giải phóng khỏi DynamoDB" \
  "$LOCK_CLEARED" "yes" \
  "Chạy lệnh 'terraform force-unlock -force mock-lock-9999' theo mục 2.1"

# 2. Kiểm tra aws_vpc.main tồn tại trong State
HAS_VPC_MAIN="no"
if terraform state list 2>/dev/null | grep -q "aws_vpc.main"; then
  HAS_VPC_MAIN="yes"
fi

check "State quản lý tài nguyên 'aws_vpc.main' (di chuyển thành công)" \
  "$HAS_VPC_MAIN" "yes" \
  "Chạy 'terraform state mv aws_vpc.core aws_vpc.main' theo mục 2.2"

# 3. Kiểm tra aws_vpc.core không còn trong State
HAS_NO_VPC_CORE="yes"
if terraform state list 2>/dev/null | grep -q "aws_vpc.core"; then
  HAS_NO_VPC_CORE="no"
fi

check "Tài nguyên cũ 'aws_vpc.core' không còn xuất hiện trong State" \
  "$HAS_NO_VPC_CORE" "yes" \
  "Đảm bảo đã chạy lệnh 'terraform state mv'"

# 4. Kiểm tra bài tập: Subnet 10.0.99.0/24 vẫn tồn tại trên Cloud
HAS_CLOUD_SUBNET="no"
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=cidr-block,Values=10.0.99.0/24" \
  --query "Subnets[0].SubnetId" \
  --output text 2>/dev/null)

if [ -n "$SUBNET_ID" ] && [ "$SUBNET_ID" != "None" ]; then
  HAS_CLOUD_SUBNET="yes"
fi

check "Bài tập: Subnet 10.0.99.0/24 vẫn tồn tại nguyên vẹn trên Cloud" \
  "$HAS_CLOUD_SUBNET" "yes" \
  "Tạo subnet 10.0.99.0/24 bằng Terraform apply theo bài tập mục 3"

# 5. Kiểm tra bài tập: Subnet đã được gỡ (rm) khỏi Terraform State
SUBNET_IN_STATE="yes"
if ! terraform state list 2>/dev/null | grep -q "aws_subnet.test_subnet"; then
  SUBNET_IN_STATE="no"
fi

check "Bài tập: Tài nguyên 'aws_subnet.test_subnet' đã được gỡ khỏi State" \
  "$SUBNET_IN_STATE" "no" \
  "Chạy 'terraform state rm aws_subnet.test_subnet' theo bài tập mục 3"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Bạn đã làm chủ các kỹ thuật can thiệp State nâng cao."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
