#!/bin/bash
# step2-verify.sh — Kiểm tra Bước 2: Security Groups

source /tmp/lab-env.sh 2>/dev/null || true

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  local expected="$3"
  if [ "$result" = "$expected" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc (nhận: '$result', cần: '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Kiểm tra Bước 2: Security Groups ==="
echo ""

# 1. Security Group "web-server-sg" tồn tại
SG_NAME=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=web-server-sg" \
  --query 'SecurityGroups[0].GroupName' --output text 2>/dev/null)
check "Security Group 'web-server-sg' đã được tạo" "$SG_NAME" "web-server-sg"

# Lấy SG_ID để kiểm tra rules
SG_ID_CHECK=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=web-server-sg" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)

# 2. Port 80 được mở cho 0.0.0.0/0
PORT_80=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID_CHECK \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`] | [?IpRanges[?CidrIp=='0.0.0.0/0']].FromPort" \
  --output text 2>/dev/null)
check "Port 80 (HTTP) mở cho 0.0.0.0/0" "$PORT_80" "80"

# 3. Port 22 được mở (chỉ kiểm tra tồn tại, không kiểm tra IP cụ thể)
PORT_22=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID_CHECK \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`].FromPort" \
  --output text 2>/dev/null)
check "Port 22 (SSH) đã được cấu hình" "$PORT_22" "22"

# 4. Port 443 KHÔNG được mở (đã bị revoke)
PORT_443=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID_CHECK \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\`].FromPort" \
  --output text 2>/dev/null)
check "Port 443 đã bị thu hồi (rule không cần thiết)" "${PORT_443:-NONE}" "NONE"

# 5. SG gắn với đúng VPC
SG_VPC=$(aws ec2 describe-security-groups \
  --group-ids $SG_ID_CHECK \
  --query 'SecurityGroups[0].VpcId' --output text 2>/dev/null)
VPC_ID_CHECK=$(aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
check "Security Group gắn với VPC devops-vpc" "$SG_VPC" "$VPC_ID_CHECK"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS thành công / $((PASS + FAIL)) kiểm tra"

if [ $FAIL -eq 0 ]; then
  echo "🎉 Security Group cấu hình đúng! Tiếp tục Bước 3."
  exit 0
else
  echo "⚠️  Có $FAIL lỗi. Đọc lại hướng dẫn và thử lại."
  exit 1
fi
