#!/bin/bash
# step1-verify.sh — Lab 14: Kiểm tra Cost Allocation Tags với AWS CLI

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

echo "=== Bước 1: Kiểm Tra Cost Allocation Tags ==="
echo ""

source /tmp/lab-env.sh 2>/dev/null

get_tag() {
  local INST_ID=$1
  local KEY=$2
  aws ec2 describe-instances \
    --instance-ids "$INST_ID" \
    --query "Reservations[0].Instances[0].Tags[?Key=='$KEY'].Value | [0]" \
    --output text 2>/dev/null
}

# 1. Kiểm tra api-server-prod
check "api-server-prod có tag Project=e-commerce" \
  "$(get_tag "$SRV_API" "Project")" "e-commerce" \
  "Gắn tag Project=e-commerce cho \$SRV_API"

check "api-server-prod có tag CostCenter=CC-001" \
  "$(get_tag "$SRV_API" "CostCenter")" "CC-001" \
  "Gắn tag CostCenter=CC-001 cho \$SRV_API"

# 2. Kiểm tra web-server-prod
check "web-server-prod có tag Project=e-commerce" \
  "$(get_tag "$SRV_WEB" "Project")" "e-commerce" \
  "Gắn tag Project=e-commerce cho \$SRV_WEB"

# 3. Kiểm tra worker-prod
check "worker-prod có tag Project=data-platform" \
  "$(get_tag "$SRV_WORKER" "Project")" "data-platform" \
  "Gắn tag Project=data-platform cho \$SRV_WORKER"

# 4. Kiểm tra reporting-server
check "reporting-server có tag Project=internal-tools" \
  "$(get_tag "$SRV_REPORT" "Project")" "internal-tools" \
  "Gắn tag Project=internal-tools cho \$SRV_REPORT"

# 5. Kiểm tra bài tập: old-test-server
check "Bài tập: old-test-server có tag Project=internal-tools" \
  "$(get_tag "$SRV_TEST" "Project")" "internal-tools" \
  "Gắn tag Project=internal-tools cho \$SRV_TEST"

check "Bài tập: old-test-server có tag Environment=development" \
  "$(get_tag "$SRV_TEST" "Environment")" "development" \
  "Gắn tag Environment=development cho \$SRV_TEST"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Tất cả máy ảo đã tuân thủ chuẩn Cost Allocation Tags."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
