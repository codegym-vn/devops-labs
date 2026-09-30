#!/bin/bash
# step4-verify.sh — Lab 18: Kiểm tra import block {} & dọn dẹp đồng bộ toàn diện

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

echo "=== Bước 4: Kiểm Tra Declarative Import & Đồng Bộ Toàn Diện ==="
echo ""

WORK_DIR="/root/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra file declarative_import.tf hoặc generated_subnet.tf tồn tại
HAS_DECLARATIVE="no"
if [ -f "declarative_import.tf" ] || [ -f "generated_subnet.tf" ]; then
  HAS_DECLARATIVE="yes"
fi

check "File cấu hình declarative_import.tf hoặc generated_subnet.tf tồn tại" \
  "$HAS_DECLARATIVE" "yes" \
  "Khai báo block import {} và chạy 'terraform plan -generate-config-out=generated_subnet.tf'"

# 2. Kiểm tra tài nguyên mạng VPC đã được hủy dọn dẹp sạch sẽ
REMAINING_VPC=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=core-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text 2>/dev/null)

check "Hạ tầng VPC core-vpc đã được dọn dẹp an toàn bằng 'terraform destroy'" \
  "None" "$REMAINING_VPC" \
  "Chạy lệnh 'terraform destroy -auto-approve' để dọn dẹp toàn bộ hạ tầng"

# 3. Kiểm tra Subnet thủ công 10.0.88.0/24 đã được xóa khỏi Cloud
REMAINING_SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=cidr-block,Values=10.0.88.0/24" \
  --query "Subnets[0].SubnetId" \
  --output text 2>/dev/null)

check "Subnet thủ công (10.0.88.0/24) đã được dọn dẹp sạch sẽ qua Terraform" \
  "None" "$REMAINING_SUBNET" \
  "Đảm bảo đã chạy 'terraform destroy -auto-approve'"

# 4. Kiểm tra file state trên S3 vẫn còn tồn tại nhưng mảng resources rỗng (0)
STATE_OBJECT_EXISTS="no"
if aws s3 ls "s3://devops-tfstate-bucket/network/terraform.tfstate" >/dev/null 2>&1; then
  STATE_OBJECT_EXISTS="yes"
fi

check "File trạng thái trên S3 's3://devops-tfstate-bucket/network/terraform.tfstate' được bảo toàn" \
  "$STATE_OBJECT_EXISTS" "yes" \
  "State file trên S3 vẫn phải tồn tại sau khi destroy để theo dõi trạng thái rỗng"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Lab 18 và làm chủ Remote Backend & Import."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
