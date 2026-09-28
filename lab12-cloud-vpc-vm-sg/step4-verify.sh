#!/bin/bash
# step4-verify.sh — Lab 12: Kiểm tra dọn dẹp tài nguyên với AWS CLI

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

echo "=== Bước 4: Kiểm Tra Quy Trình Dọn Dẹp Tài Nguyên ==="
echo ""

source /tmp/lab-env.sh 2>/dev/null

# 1. Kiểm tra VPC vẫn tồn tại để xác minh phiên làm việc
check "Hạ tầng VPC 'devops-vpc' đã được xây dựng thành công" \
  "nonempty" "$VPC_ID" \
  "VPC ID không tìm thấy trong /tmp/lab-env.sh"

# 2. Kiểm tra các instances đã được chuyển sang trạng thái shutting-down hoặc terminated
RUNNING_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[].Instances[].InstanceId" --output text 2>/dev/null)

check "Tất cả máy ảo EC2 đã được Terminate (không còn máy nào chạy ngầm tốn phí)" \
  "$( [ -z "$RUNNING_INSTANCES" ] && echo "terminated" || echo "$RUNNING_INSTANCES" )" \
  "terminated" \
  "Chạy lệnh terminate-instances ở Mục 3 để giải phóng máy ảo"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Lab 12 với AWS CLI và LocalStack!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy thực hiện lệnh hủy máy ảo để dọn dẹp sạch sẽ."
  exit 1
fi
