#!/bin/bash
# step4-verify.sh — Scale-out + Cleanup
source /tmp/lab-env.sh 2>/dev/null || true
PASS=0; FAIL=0

check() {
  [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } \
                  || { echo "  ❌ $1 (nhận: '$2', cần: '$3')"; FAIL=$((FAIL+1)); }
}

echo "=== Kiểm tra Bước 4: Scale-out + Cleanup ==="
echo ""

# ASG desired = 3
ASG_DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query 'AutoScalingGroups[0].DesiredCapacity' --output text 2>/dev/null || echo "0")
check "ASG đã scale-out lên desired = 3" "$ASG_DESIRED" "3"

# app-3 đã từng chạy (benchmark file tồn tại)
BENCH_EXISTS=$([ -f /tmp/bench-after.txt ] && echo "yes" || echo "no")
check "Đã chạy benchmark sau scale-out" "$BENCH_EXISTS" "yes"

# Containers đã dọn dẹp
for i in 1 2 3; do
  EXIST=$(docker ps -a --filter "name=app-${i}" --format "{{.Names}}" 2>/dev/null)
  check "Container app-${i} đã xóa" "$EXIST" ""
done

# ALB đã xóa
ALB_REMAIN=$(aws elbv2 describe-load-balancers --names web-alb \
  --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
check "ALB 'web-alb' đã xóa" "$ALB_REMAIN" "0"

# ASG đã xóa
ASG_REMAIN=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query 'length(AutoScalingGroups)' --output text 2>/dev/null || echo "0")
check "ASG 'web-asg' đã xóa" "$ASG_REMAIN" "0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🏆 Hoàn thành Lab 13! ALB + ASG đã thành thạo."; exit 0; } \
               || { echo "⚠️  $FAIL lỗi cần sửa."; exit 1; }
