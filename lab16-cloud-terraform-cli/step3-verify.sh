#!/bin/bash
# step3-verify.sh — Lab 16: Kiểm tra triển khai EC2, Security Group & State File

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

echo "=== Bước 3: Kiểm Tra Triển Khai EC2, Security Group & State File ==="
echo ""

WORK_DIR="/root/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra compute.tf tồn tại
HAS_COMPUTE="no"
[ -f "compute.tf" ] && HAS_COMPUTE="yes"

check "File cấu hình compute.tf tồn tại" \
  "$HAS_COMPUTE" "yes" \
  "Tạo file compute.tf theo mục 2.1"

# 2. Kiểm tra file terraform.tfstate tồn tại
HAS_STATE="no"
[ -f "terraform.tfstate" ] && HAS_STATE="yes"

check "File trạng thái terraform.tfstate đã được tạo" \
  "$HAS_STATE" "yes" \
  "Chạy 'terraform apply tfplan' để áp dụng hạ tầng và sinh file state"

# 3. Kiểm tra resource aws_instance.web và aws_security_group.web_sg trong state
STATE_HAS_EC2="no"
STATE_HAS_SG="no"
if terraform state list 2>/dev/null | grep -q "aws_instance.web"; then
  STATE_HAS_EC2="yes"
fi
if terraform state list 2>/dev/null | grep -q "aws_security_group.web_sg"; then
  STATE_HAS_SG="yes"
fi

check "State quản lý tài nguyên aws_instance.web" \
  "$STATE_HAS_EC2" "yes" \
  "Chạy 'terraform apply' để tạo máy ảo EC2"

check "State quản lý tài nguyên aws_security_group.web_sg" \
  "$STATE_HAS_SG" "yes" \
  "Chạy 'terraform apply' để tạo Security Group"

# 4. Đối chứng trực tiếp với LocalStack qua AWS CLI
EC2_STATE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tf-web-server" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null)

check "Máy ảo 'tf-web-server' đang tồn tại và hoạt động trên Cloud" \
  "$EC2_STATE" "running" \
  "Kiểm tra lại lệnh apply hoặc gọi 'aws ec2 describe-instances'"

# 5. Kiểm tra outputs web_instance_id
OUTPUT_ID=$(terraform output -raw web_instance_id 2>/dev/null)

check "Output 'web_instance_id' trích xuất thành công ID máy ảo" \
  "nonempty" "$OUTPUT_ID" \
  "Kiểm tra lại định nghĩa output web_instance_id trong outputs.tf và apply lại"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Bạn đã nắm vững cơ chế Plan, Apply và quản lý State File."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
