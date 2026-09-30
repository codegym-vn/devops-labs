#!/bin/bash
# step2-verify.sh — Lab 19: Kiểm tra phân tích trạng thái Node Conditions & Allocatable

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

echo "=== Bước 2: Kiểm Tra Trạng Thái Node Conditions & Allocatable ==="
echo ""

# 1. Kiểm tra node01 ở trạng thái Ready = True
READY_STATUS=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
check "Node 'node01' báo cáo điều kiện sức khỏe Ready = True" \
  "$READY_STATUS" "True" \
  "Kiểm tra trạng thái node01 bằng 'kubectl get nodes'"

# 2. Kiểm tra các cảnh báo áp lực đều là False
MEM_PRESSURE=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="MemoryPressure")].status}' 2>/dev/null)
DISK_PRESSURE=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}' 2>/dev/null)
PID_PRESSURE=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="PIDPressure")].status}' 2>/dev/null)

HEALTHY="no"
if [ "$MEM_PRESSURE" = "False" ] && [ "$DISK_PRESSURE" = "False" ] && [ "$PID_PRESSURE" = "False" ]; then
  HEALTHY="yes"
fi

check "Node 'node01' an toàn: MemoryPressure, DiskPressure, PIDPressure đều là False" \
  "$HEALTHY" "yes" \
  "Đảm bảo máy chủ không bị quá tải tài nguyên"

# 3. Kiểm tra bài tập: file /tmp/node01-pods.txt tồn tại
HAS_PODS_FILE="no"
[ -f "/tmp/node01-pods.txt" ] && HAS_PODS_FILE="yes"

check "Bài tập: Tệp '/tmp/node01-pods.txt' đã được tạo" \
  "$HAS_PODS_FILE" "yes" \
  "Chạy lệnh trích xuất jsonpath pods vào /tmp/node01-pods.txt theo mục 3"

# 4. Kiểm tra giá trị pods trích xuất trùng khớp với thực tế
ACTUAL_PODS=$(kubectl get node node01 -o jsonpath='{.status.allocatable.pods}' 2>/dev/null | tr -d '[:space:]')
SAVED_PODS=$(cat /tmp/node01-pods.txt 2>/dev/null | tr -d '[:space:]')

check "Giá trị Allocatable Pods ($SAVED_PODS) trùng khớp chính xác với thông số node01" \
  "$SAVED_PODS" "$ACTUAL_PODS" \
  "Trích xuất lại đúng thuộc tính .status.allocatable.pods"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Bạn đã làm chủ việc đánh giá điều kiện sức khỏe và năng lực của Node."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
