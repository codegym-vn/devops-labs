#!/bin/bash
# step1-verify.sh — Lab 19: Kiểm tra kiến trúc cụm K8s & Kubeconfig

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

echo "=== Bước 1: Kiểm Tra Cụm Kubernetes & Cấu Hình Kubeconfig ==="
echo ""

# 1. Kiểm tra cụm có đủ ít nhất 2 nodes
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
check "Cụm Kubernetes có đầy đủ 2 Nodes (controlplane & node01)" \
  "$NODE_COUNT" "2" \
  "Kiểm tra cụm bằng lệnh 'kubectl get nodes'"

# 2. Kiểm tra các nodes đều ở trạng thái Ready
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
check "Cả 2 Nodes đều đang hoạt động khỏe mạnh (STATUS: Ready)" \
  "$READY_NODES" "2" \
  "Đảm bảo kubelet trên các node đang chạy bình thường"

# 3. Kiểm tra bài tập: file /tmp/current-context.txt tồn tại
HAS_CONTEXT_FILE="no"
[ -f "/tmp/current-context.txt" ] && HAS_CONTEXT_FILE="yes"

check "Bài tập: Tệp '/tmp/current-context.txt' đã được tạo" \
  "$HAS_CONTEXT_FILE" "yes" \
  "Chạy lệnh 'kubectl config current-context > /tmp/current-context.txt' theo mục 3"

# 4. Kiểm tra nội dung context trùng khớp với cấu hình hệ thống
SAVED_CONTEXT=$(cat /tmp/current-context.txt 2>/dev/null | tr -d '[:space:]')
ACTUAL_CONTEXT=$(kubectl config current-context 2>/dev/null | tr -d '[:space:]')

check "Nội dung tệp lưu đúng tên Current-Context hiện hành ($ACTUAL_CONTEXT)" \
  "$SAVED_CONTEXT" "$ACTUAL_CONTEXT" \
  "Xuất lại tên context vào tệp /tmp/current-context.txt"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Bạn đã kết nối và nắm vững thông số cụm Kubernetes."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
