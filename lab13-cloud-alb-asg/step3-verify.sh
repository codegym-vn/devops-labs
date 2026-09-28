#!/bin/bash
# step3-verify.sh — Lab 13: Kiểm tra Target Health & Đăng ký mục tiêu

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

echo "=== Bước 3: Kiểm Tra Target Health & Đăng Ký Mục Tiêu ==="
echo ""

source /tmp/lab-env.sh 2>/dev/null

# 1. Kiểm tra Target Group ARN tồn tại
check "Target Group ARN đã được lưu trong môi trường" \
  "nonempty" "$TG_ARN" \
  "Biến \$TG_ARN không tìm thấy trong /tmp/lab-env.sh"

# 2. Kiểm tra Target Group có mục tiêu đăng ký
TARGET_COUNT=$(aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query "length(TargetHealthDescriptions)" --output text 2>/dev/null)

check "Target Group đã nhận diện mục tiêu từ Auto Scaling Group" \
  "$( [ "$TARGET_COUNT" -ge 1 ] && echo ok || echo fail )" "ok" \
  "Chờ 10-15s để ASG tự động đăng ký các instances vào Target Group"

# 3. Kiểm tra thuộc tính thuật toán của Target Group
ALGO=$(aws elbv2 describe-target-group-attributes \
  --target-group-arn "$TG_ARN" \
  --query "Attributes[?Key=='load_balancing.algorithm.type'].Value | [0]" --output text 2>/dev/null)

check "Target Group sử dụng thuật toán phân tải 'round_robin'" \
  "$ALGO" "round_robin" \
  "Chạy mục 3.2: aws elbv2 describe-target-group-attributes ..."

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Các mục tiêu đã được đăng ký và sẵn sàng phân tải."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
