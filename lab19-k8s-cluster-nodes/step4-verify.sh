#!/bin/bash
# step4-verify.sh — Lab 19: Kiểm tra quy trình bảo trì Cordon/Uncordon & Dọn dẹp

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

echo "=== Bước 4: Kiểm Tra Quy Trình Bảo Trì & Dọn Dẹp Cụm K8s ==="
echo ""

# 1. Kiểm tra node01 không còn bị SchedulingDisabled
IS_CORDONED=$(kubectl get node node01 --no-headers 2>/dev/null | grep -c "SchedulingDisabled" || true)
check "Worker Node 'node01' đã được mở khóa an toàn (không còn SchedulingDisabled)" \
  "$IS_CORDONED" "0" \
  "Chạy lệnh mở khóa: kubectl uncordon node01"

# 2. Kiểm tra cả 2 nodes đều ở trạng thái Ready
READY_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
check "Cả 2 Nodes đều đang ở trạng thái hoạt động bình thường (Ready)" \
  "$READY_COUNT" "2" \
  "Đảm bảo các node đều đang Ready"

# 3. Kiểm tra pod ssd-app đã được xóa
SSD_POD_EXISTS=$(kubectl get pod ssd-app --no-headers 2>/dev/null | wc -l | tr -d ' ')
check "Bài tập: Pod thử nghiệm 'ssd-app' đã được dọn dẹp sạch sẽ" \
  "$SSD_POD_EXISTS" "0" \
  "Chạy lệnh: kubectl delete pod ssd-app"

# 4. Kiểm tra pod pending-test đã được xóa
PENDING_POD_EXISTS=$(kubectl get pod pending-test --no-headers 2>/dev/null | wc -l | tr -d ' ')
check "Bài tập: Pod thử nghiệm 'pending-test' đã được dọn dẹp sạch sẽ" \
  "$PENDING_POD_EXISTS" "0" \
  "Chạy lệnh: kubectl delete pod pending-test"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Xuất sắc! Bạn đã hoàn thành toàn bộ bài Lab 19 và làm chủ kỹ năng quản trị Node."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
