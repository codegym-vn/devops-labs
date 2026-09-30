#!/bin/bash
# step4-verify.sh — Lab 16: Kiểm tra In-place Update, Destroy & Re-creation

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

echo "=== Bước 4: Kiểm Tra Cập Nhật Hạ Tầng & Tái Lập (Idempotency) ==="
echo ""

WORK_DIR="/root/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra cấu hình compute.tf có rule mở cổng 443 (HTTPS)
HAS_PORT_443="no"
if grep -q "443" compute.tf 2>/dev/null; then
  HAS_PORT_443="yes"
fi

check "File compute.tf đã cấu hình mở cổng HTTPS (port 443)" \
  "$HAS_PORT_443" "yes" \
  "Mở compute.tf và bổ sung block ingress cho port 443 như mục 2.1"

# 2. Kiểm tra State và LocalStack: Tài nguyên đã được tái lập thành công với apply
STATE_EXISTS="no"
[ -f "terraform.tfstate" ] && STATE_EXISTS="yes"

check "File terraform.tfstate tồn tại" \
  "$STATE_EXISTS" "yes" \
  "Chạy 'terraform apply -auto-approve' để tái lập lại hạ tầng theo bài tập mục 3"

# 3. Kiểm tra Security Group trên Cloud có quy tắc mở port 443
SG_RULES=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=tf-web-sg" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\`].FromPort" \
  --output text 2>/dev/null)

check "Security Group 'tf-web-sg' trên Cloud đã cập nhật mở port 443" \
  "nonempty" "$SG_RULES" \
  "Chạy 'terraform apply -auto-approve' để đẩy rule port 443 lên hạ tầng"

# 4. Kiểm tra máy ảo EC2 đang chạy sau khi tái lập
EC2_STATUS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=tf-web-server" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null)

check "Máy ảo EC2 'tf-web-server' đang hoạt động (running)" \
  "$EC2_STATUS" "running" \
  "Chạy 'terraform apply -auto-approve' để kích hoạt lại máy ảo"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Bước 4 và làm chủ chu trình Terraform CLI."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
