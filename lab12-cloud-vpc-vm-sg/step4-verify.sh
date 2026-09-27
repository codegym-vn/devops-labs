#!/bin/bash
# step4-verify.sh — Kiểm tra Bước 4: End-to-end test + Cleanup

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

echo "=== Kiểm tra Bước 4: Kiểm thử và Cleanup ==="
echo ""

# 1. Tất cả tài nguyên AWS đã được dọn dẹp
VPC_REMAIN=$(aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'length(Vpcs)' --output text 2>/dev/null)
check "VPC đã được xóa hoàn toàn" "$VPC_REMAIN" "0"

SG_REMAIN=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=web-server-sg" \
  --query 'length(SecurityGroups)' --output text 2>/dev/null)
check "Security Group đã được xóa" "$SG_REMAIN" "0"

KEYPAIR_REMAIN=$(aws ec2 describe-key-pairs \
  --key-names devops-keypair \
  --query 'length(KeyPairs)' --output text 2>/dev/null || echo "0")
check "Key Pair đã được xóa" "$KEYPAIR_REMAIN" "0"

# 2. Docker container đã dừng
CONTAINER_EXIST=$(docker ps -a --filter "name=web-server-1" --format "{{.Names}}" 2>/dev/null)
check "Docker container web-server-1 đã dừng và xóa" "$CONTAINER_EXIST" ""

# 3. Private key file đã xóa
KEY_EXIST=$([ -f ~/.ssh/devops-keypair.pem ] && echo "exists" || echo "deleted")
check "Private key file đã được xóa" "$KEY_EXIST" "deleted"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS thành công / $((PASS + FAIL)) kiểm tra"

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "🏆 Hoàn thành Lab 12!"
  echo "   Tất cả tài nguyên đã được tạo, kiểm thử và dọn dẹp đúng cách."
  exit 0
else
  echo ""
  echo "⚠️  Còn $FAIL tài nguyên chưa được xóa."
  echo "   Chạy lại cleanup script và kiểm tra lại."
  exit 1
fi
