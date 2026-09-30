#!/bin/bash
# step4-verify.sh — Lab 17: Kiểm tra triển khai Prod, kiểm thử cô lập & dọn dẹp

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

echo "=== Bước 4: Kiểm Tra Triển Khai Prod, Cô Lập & Dọn Dẹp ==="
echo ""

WORK_DIR="/root/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra tài nguyên prod-vpc đã được dọn dẹp an toàn
PROD_VPC=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=prod-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text 2>/dev/null)

check "Hạ tầng Production (prod-vpc) đã được hủy dọn dẹp thành công" \
  "None" "$PROD_VPC" \
  "Thực thi 'terraform destroy -var-file=environments/prod.tfvars -auto-approve' trong workspace prod"

# 2. Kiểm tra máy ảo prod-web-server đã được hủy
PROD_EC2=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=prod-web-server" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null)

check "Máy ảo EC2 prod-web-server đã được hủy thành công" \
  "None" "$PROD_EC2" \
  "Đảm bảo đã chạy lệnh destroy đối với môi trường prod"

# 3. Kiểm tra workspace hiện tại đã chuyển về an toàn (không bị kẹt ở prod đã xóa)
CURRENT_WS=$(terraform workspace show 2>/dev/null)
WS_VALID="no"
if [ "$CURRENT_WS" = "default" ] || [ "$CURRENT_WS" = "dev" ]; then
  WS_VALID="yes"
fi

check "Con trỏ Workspace đang ở trạng thái an toàn ('default' hoặc 'dev')" \
  "$WS_VALID" "yes" \
  "Chuyển con trỏ workspace về dev hoặc default bằng 'terraform workspace select ...'"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Lab 17 và làm chủ Modules & Workspaces."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
