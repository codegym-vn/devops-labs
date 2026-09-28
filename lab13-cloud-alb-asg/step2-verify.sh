#!/bin/bash
# step2-verify.sh — Lab 13: Kiểm tra Target Group, ALB & Listener

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

echo "=== Bước 2: Kiểm Tra ALB, Target Group & Listener ==="
echo ""

# 1. Kiểm tra Target Group web-tg tồn tại
TG_ARN=$(aws elbv2 describe-target-groups \
  --names "web-tg" \
  --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null)

check "Target Group 'web-tg' đã được tạo" \
  "nonempty" "$TG_ARN" \
  "Chạy mục 2.1: aws elbv2 create-target-group --name web-tg ..."

# 2. Kiểm tra Load Balancer web-alb tồn tại
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names "web-alb" \
  --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)

check "Application Load Balancer 'web-alb' đã được tạo" \
  "nonempty" "$ALB_ARN" \
  "Chạy mục 2.2: aws elbv2 create-load-balancer --name web-alb ..."

# 3. Kiểm tra Listener tồn tại trên cổng 80
LISTENER_PORT=$(aws elbv2 describe-listeners \
  --load-balancer-arn "$ALB_ARN" \
  --query "Listeners[0].Port" --output text 2>/dev/null)

check "Listener cổng 80 đã được cấu hình trên ALB" \
  "$LISTENER_PORT" "80" \
  "Chạy mục 2.3: aws elbv2 create-listener --load-balancer-arn \$ALB_ARN --port 80 ..."

# 4. Kiểm tra Target Group đã gắn vào ASG web-asg
ATTACHED_TG=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query "AutoScalingGroups[0].TargetGroupARNs[0]" --output text 2>/dev/null)

check "Target Group đã được gắn (attached) vào Auto Scaling Group" \
  "nonempty" "$ATTACHED_TG" \
  "Chạy mục 2.4: aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name web-asg ..."

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Hệ thống cân bằng tải ALB và Target Group đã được đấu nối chuẩn xác."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
