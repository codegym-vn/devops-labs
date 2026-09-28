#!/bin/bash
# step2-verify.sh — Lab 12: Kiểm tra Security Groups với AWS CLI

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

echo "=== Bước 2: Kiểm Tra Security Groups & Quy Tắc Tường Lửa ==="
echo ""

# 1. Kiểm tra web-sg tồn tại
WEB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=web-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Security Group 'web-sg' tồn tại" \
  "nonempty" "$WEB_SG_ID" \
  "Chạy mục 2.1: aws ec2 create-security-group --group-name web-sg ..."

# 2. Kiểm tra web-sg có port 80 từ 0.0.0.0/0
HAS_PORT_80=$(aws ec2 describe-security-groups \
  --group-ids "$WEB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\` && contains(IpRanges[].CidrIp, '0.0.0.0/0')].FromPort" \
  --output text 2>/dev/null)

check "web-sg có Inbound rule mở Port 80 cho 0.0.0.0/0" \
  "nonempty" "$HAS_PORT_80" \
  "Chạy mục 2.2: aws ec2 authorize-security-group-ingress --group-id \$WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0"

# 3. Kiểm tra web-sg có port 22 từ 10.0.0.0/16
HAS_PORT_22=$(aws ec2 describe-security-groups \
  --group-ids "$WEB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && contains(IpRanges[].CidrIp, '10.0.0.0/16')].FromPort" \
  --output text 2>/dev/null)

check "web-sg có Inbound rule mở Port 22 cho 10.0.0.0/16" \
  "nonempty" "$HAS_PORT_22" \
  "Chạy mục 2.2: aws ec2 authorize-security-group-ingress --group-id \$WEB_SG_ID --protocol tcp --port 22 --cidr 10.0.0.0/16"

# 4. Kiểm tra db-sg tồn tại
DB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=db-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Security Group 'db-sg' tồn tại" \
  "nonempty" "$DB_SG_ID" \
  "Chạy mục 2.3: aws ec2 create-security-group --group-name db-sg ..."

# 5. Kiểm tra db-sg có port 5432 nhận nguồn từ web-sg
HAS_PORT_5432=$(aws ec2 describe-security-groups \
  --group-ids "$DB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`5432\` && contains(UserIdGroupPairs[].GroupId, '$WEB_SG_ID')].FromPort" \
  --output text 2>/dev/null)

check "db-sg mở Port 5432 CHỈ từ source-group web-sg" \
  "nonempty" "$HAS_PORT_5432" \
  "Chạy mục 2.4: aws ec2 authorize-security-group-ingress --group-id \$DB_SG_ID --protocol tcp --port 5432 --source-group \$WEB_SG_ID"

# 6. Kiểm tra bài tập: web-sg mở port 443 từ 0.0.0.0/0
HAS_PORT_443=$(aws ec2 describe-security-groups \
  --group-ids "$WEB_SG_ID" \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\` && contains(IpRanges[].CidrIp, '0.0.0.0/0')].FromPort" \
  --output text 2>/dev/null)

check "Bài tập: web-sg mở thêm Port 443 (HTTPS) cho 0.0.0.0/0" \
  "nonempty" "$HAS_PORT_443" \
  "Chạy bài tập: aws ec2 authorize-security-group-ingress --group-id \$WEB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Hệ thống tường lửa Security Group đã được gia cố chuẩn bảo mật."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
