#!/bin/bash
# step3-verify.sh — Lab 17: Kiểm tra Workspaces & Triển khai môi trường Dev

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

echo "=== Bước 3: Kiểm Tra Workspaces & Triển Khai Môi Trường Dev ==="
echo ""

WORK_DIR="/root/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra các file môi trường .tfvars
HAS_TFVARS="yes"
for f in environments/dev.tfvars environments/prod.tfvars; do
  if [ ! -f "$f" ]; then
    HAS_TFVARS="no"
    break
  fi
done

check "Các file environments/dev.tfvars và environments/prod.tfvars tồn tại" \
  "$HAS_TFVARS" "yes" \
  "Tạo các file tham số môi trường theo mục 2.1"

# 2. Kiểm tra Workspace 'dev' tồn tại
HAS_DEV_WS="no"
if terraform workspace list 2>/dev/null | grep -q "dev"; then
  HAS_DEV_WS="yes"
fi

check "Workspace 'dev' đã được khởi tạo trong Terraform" \
  "$HAS_DEV_WS" "yes" \
  "Chạy 'terraform workspace new dev' theo mục 2.2"

# 3. Kiểm tra file trạng thái cô lập của dev tồn tại
HAS_DEV_STATE="no"
if [ -f "terraform.tfstate.d/dev/terraform.tfstate" ]; then
  HAS_DEV_STATE="yes"
fi

check "File trạng thái terraform.tfstate.d/dev/terraform.tfstate tồn tại" \
  "$HAS_DEV_STATE" "yes" \
  "Chạy 'terraform apply dev.tfplan' trong workspace dev để khởi tạo state"

# 4. Kiểm tra VPC của dev trên LocalStack
DEV_VPC_CIDR=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=dev-vpc" \
  --query "Vpcs[0].CidrBlock" \
  --output text 2>/dev/null)

check "VPC 'dev-vpc' đang hoạt động trên Cloud với CIDR 10.10.0.0/16" \
  "$DEV_VPC_CIDR" "10.10.0.0/16" \
  "Kiểm tra lại apply môi trường dev hoặc gọi 'aws ec2 describe-vpcs'"

# 5. Kiểm tra máy ảo EC2 của dev
DEV_EC2_STATE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-web-server" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null)

check "Máy ảo EC2 'dev-web-server' đang hoạt động (running)" \
  "$DEV_EC2_STATE" "running" \
  "Kiểm tra lại trạng thái máy ảo EC2 trong môi trường dev"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Bạn đã làm chủ cơ chế Workspaces và triển khai thành công môi trường Dev."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
