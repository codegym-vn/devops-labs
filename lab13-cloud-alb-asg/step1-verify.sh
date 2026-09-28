#!/bin/bash
# step1-verify.sh — Lab 13: Kiểm tra Launch Template & Auto Scaling Group

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

echo "=== Bước 1: Kiểm Tra Launch Template & Auto Scaling Group ==="
echo ""

# 1. Kiểm tra Security Group alb-sg
ALB_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=alb-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Security Group 'alb-sg' đã được tạo" \
  "nonempty" "$ALB_SG" \
  "Chạy mục 1.1: aws ec2 create-security-group --group-name alb-sg ..."

# 2. Kiểm tra Security Group app-sg
APP_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=app-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Security Group 'app-sg' đã được tạo" \
  "nonempty" "$APP_SG" \
  "Chạy mục 1.1: aws ec2 create-security-group --group-name app-sg ..."

# 3. Kiểm tra Launch Template web-launch-template
LT_NAME=$(aws ec2 describe-launch-templates \
  --launch-template-names "web-launch-template" \
  --query "LaunchTemplates[0].LaunchTemplateName" --output text 2>/dev/null)

check "Launch Template 'web-launch-template' tồn tại" \
  "$LT_NAME" "web-launch-template" \
  "Chạy mục 1.2: aws ec2 create-launch-template --launch-template-name web-launch-template ..."

# 4. Kiểm tra Auto Scaling Group web-asg
ASG_DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query "AutoScalingGroups[0].DesiredCapacity" --output text 2>/dev/null)

check "Auto Scaling Group 'web-asg' hoạt động với DesiredCapacity = 2" \
  "$ASG_DESIRED" "2" \
  "Chạy mục 1.3: aws autoscaling create-auto-scaling-group --auto-scaling-group-name web-asg --desired-capacity 2 ..."

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Launch Template và Auto Scaling Group đã sẵn sàng."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
