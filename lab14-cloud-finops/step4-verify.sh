#!/bin/bash
# step4-verify.sh — Lab 14: Kiểm tra Idle Detection, Báo cáo & Hủy Instance với AWS CLI

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

echo "=== Bước 4: Kiểm Tra Idle Detection & Thực Thi FinOps ==="
echo ""

source /tmp/lab-env.sh 2>/dev/null

# 1. Báo cáo tối ưu /tmp/finops-report.md đã được tạo
check "Báo cáo tối ưu /tmp/finops-report.md đã được tạo" \
  "$(test -f /tmp/finops-report.md && echo ok)" "ok" \
  "Chạy mục 4.2 để tạo báo cáo"

# 2. Báo cáo có đề xuất TERMINATE
SUGGEST_TERMINATE=$(grep -c -i "terminate" /tmp/finops-report.md 2>/dev/null)
check "Báo cáo có đề xuất TERMINATE cho server lãng phí" \
  "$([ ${SUGGEST_TERMINATE:-0} -ge 1 ] && echo ok)" "ok" \
  "Thêm đề xuất Terminate cho old-test-server (CPU 1.2%)"

# 3. Báo cáo có ước tính tiết kiệm
HAS_SAVINGS=$(grep -c -i "tiết kiệm\|saving\|\%" /tmp/finops-report.md 2>/dev/null)
check "Báo cáo có ước tính % hoặc số tiền tiết kiệm" \
  "$([ ${HAS_SAVINGS:-0} -ge 1 ] && echo ok)" "ok" \
  "Ước tính mức chi phí tiết kiệm trong báo cáo"

# 4. Kiểm tra máy ảo old-test-server ($SRV_TEST) đã bị Terminate trên AWS
TEST_STATE=$(aws ec2 describe-instances \
  --instance-ids "$SRV_TEST" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null)

check "Máy ảo idle 'old-test-server' đã được Terminate trên AWS" \
  "$( [ "$TEST_STATE" = "terminated" ] || [ "$TEST_STATE" = "shutting-down" ] && echo ok || echo "$TEST_STATE" )" \
  "ok" \
  "Chạy mục 4.3: aws ec2 terminate-instances --instance-ids \$SRV_TEST"

# 5. Kiểm tra bài tập: đề xuất cho api-server-prod
HAS_API_REC=$(grep -c -i "api-server-prod" /tmp/finops-report.md 2>/dev/null)
check "Bài tập: Đã cập nhật đề xuất tối ưu cho api-server-prod vào báo cáo" \
  "$([ ${HAS_API_REC:-0} -ge 2 ] && echo ok)" "ok" \
  "Chạy lệnh ở mục 3 để bổ sung đề xuất cho api-server-prod"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ Lab 14 về Cloud FinOps!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
