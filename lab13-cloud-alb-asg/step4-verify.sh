#!/bin/bash
# step4-verify.sh — Lab 13: Kiểm tra dọn dẹp tài nguyên ALB & ASG

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

echo "=== Bước 4: Kiểm Tra Quy Trình Scale-Out & Dọn Dẹp Tài Nguyên ==="
echo ""

# 1. Kiểm tra Auto Scaling Group đã được xóa
ASG_EXISTS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query "length(AutoScalingGroups)" --output text 2>/dev/null)

check "Auto Scaling Group 'web-asg' đã được xóa thành công" \
  "$ASG_EXISTS" "0" \
  "Chạy lệnh: aws autoscaling delete-auto-scaling-group --auto-scaling-group-name web-asg --force-delete"

# 2. Kiểm tra Load Balancer web-alb đã được xóa
ALB_EXISTS=$(aws elbv2 describe-load-balancers \
  --names "web-alb" \
  --query "length(LoadBalancers)" --output text 2>/dev/null)

check "Application Load Balancer 'web-alb' đã được xóa thành công" \
  "$ALB_EXISTS" "0" \
  "Chạy lệnh: aws elbv2 delete-load-balancer --load-balancer-arn \$ALB_ARN"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Lab 13 với AWS CLI và LocalStack!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy thực hiện các lệnh dọn dẹp ở Mục 3 để hoàn tất."
  exit 1
fi
