#!/bin/bash
# step1-verify.sh — Kiểm tra Launch Template + ASG + CloudWatch Alarms
source /tmp/lab-env.sh 2>/dev/null || true
PASS=0; FAIL=0

check() {
  [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } \
                  || { echo "  ❌ $1 (nhận: '$2', cần: '$3')"; FAIL=$((FAIL+1)); }
}

echo "=== Kiểm tra Bước 1: Launch Template + ASG + Alarms ==="
echo ""

# Launch Template tồn tại
LT=$(aws ec2 describe-launch-templates \
  --launch-template-names web-server-lt \
  --query 'LaunchTemplates[0].LaunchTemplateName' --output text 2>/dev/null)
check "Launch Template 'web-server-lt' đã tạo" "$LT" "web-server-lt"

# ASG tồn tại với đúng capacity
ASG_DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query 'AutoScalingGroups[0].DesiredCapacity' --output text 2>/dev/null)
check "ASG 'web-asg' có DesiredCapacity = 2" "$ASG_DESIRED" "2"

ASG_MIN=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query 'AutoScalingGroups[0].MinSize' --output text 2>/dev/null)
check "ASG MinSize = 1" "$ASG_MIN" "1"

ASG_MAX=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query 'AutoScalingGroups[0].MaxSize' --output text 2>/dev/null)
check "ASG MaxSize = 4" "$ASG_MAX" "4"

# Scaling Policies tồn tại
SCALE_OUT=$(aws autoscaling describe-policies \
  --auto-scaling-group-name web-asg --policy-names scale-out-policy \
  --query 'ScalingPolicies[0].PolicyName' --output text 2>/dev/null)
check "Scaling Policy 'scale-out-policy' đã tạo" "$SCALE_OUT" "scale-out-policy"

SCALE_IN=$(aws autoscaling describe-policies \
  --auto-scaling-group-name web-asg --policy-names scale-in-policy \
  --query 'ScalingPolicies[0].PolicyName' --output text 2>/dev/null)
check "Scaling Policy 'scale-in-policy' đã tạo" "$SCALE_IN" "scale-in-policy"

# CloudWatch Alarms
ALARM_OUT=$(aws cloudwatch describe-alarms --alarm-names "cpu-high-scale-out" \
  --query 'MetricAlarms[0].AlarmName' --output text 2>/dev/null)
check "CloudWatch Alarm scale-out (CPU > 70%) đã tạo" "$ALARM_OUT" "cpu-high-scale-out"

ALARM_IN=$(aws cloudwatch describe-alarms --alarm-names "cpu-low-scale-in" \
  --query 'MetricAlarms[0].AlarmName' --output text 2>/dev/null)
check "CloudWatch Alarm scale-in (CPU < 30%) đã tạo" "$ALARM_IN" "cpu-low-scale-in"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 Hoàn thành! Tiếp tục Bước 2."; exit 0; } \
               || { echo "⚠️  $FAIL lỗi cần sửa."; exit 1; }
