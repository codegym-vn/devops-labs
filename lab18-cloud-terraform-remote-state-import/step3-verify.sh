#!/bin/bash
# step3-verify.sh — Lab 18: Kiểm tra import tài nguyên với lệnh terraform import

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

echo "=== Bước 3: Kiểm Tra Import Thủ Công Bằng Lệnh terraform import ==="
echo ""

WORK_DIR="/root/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra file imported.tf tồn tại
HAS_IMPORTED_TF="no"
[ -f "imported.tf" ] && HAS_IMPORTED_TF="yes"

check "File cấu hình imported.tf tồn tại trong dự án" \
  "$HAS_IMPORTED_TF" "yes" \
  "Tạo file imported.tf theo hướng dẫn mục 2.2 và 2.3"

# 2. Kiểm tra tài nguyên aws_security_group.manual_sg đã nằm trong State
HAS_SG_IN_STATE="no"
if terraform state list 2>/dev/null | grep -q "aws_security_group.manual_sg"; then
  HAS_SG_IN_STATE="yes"
fi

check "State quản lý tài nguyên 'aws_security_group.manual_sg' (import thành công)" \
  "$HAS_SG_IN_STATE" "yes" \
  "Thực thi 'terraform import aws_security_group.manual_sg \$LEGACY_SG_ID'"

# 3. Kiểm tra Security Group manual-legacy-sg tồn tại trên Cloud
SG_EXISTS="no"
if aws ec2 describe-security-groups --filters "Name=group-name,Values=manual-legacy-sg" 2>/dev/null | grep -q "manual-legacy-sg"; then
  SG_EXISTS="yes"
fi

check "Security Group 'manual-legacy-sg' đang hoạt động trên Cloud" \
  "$SG_EXISTS" "yes" \
  "Tạo SG thủ công theo mục 2.1 bằng AWS CLI"

# 4. Kiểm tra bài tập: Tag Environment = migrated
SG_TAG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=manual-legacy-sg" \
  --query "SecurityGroups[0].Tags[?Key=='Environment'].Value|[0]" \
  --output text 2>/dev/null)

check "Bài tập: Security Group đã được gắn thẻ Tag Environment = 'migrated'" \
  "$SG_TAG" "migrated" \
  "Thêm tags vào imported.tf và chạy 'terraform apply -auto-approve' theo bài tập mục 3"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Bạn đã import thành công hạ tầng cũ vào luồng quản trị IaC."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
