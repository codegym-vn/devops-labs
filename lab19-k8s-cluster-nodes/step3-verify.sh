#!/bin/bash
# step3-verify.sh — Lab 19: Kiểm tra quản trị Labels & Lập lịch Pod có điều kiện

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

echo "=== Bước 3: Kiểm Tra Quản Trị Labels & Lập Lịch Pod Có Điều Kiện ==="
echo ""

# 1. Kiểm tra node01 có nhãn hardware=ssd
HAS_SSD_LABEL="no"
if kubectl get nodes -l hardware=ssd --no-headers 2>/dev/null | grep -q "node01"; then
  HAS_SSD_LABEL="yes"
fi

check "Node 'node01' được gắn nhãn 'hardware=ssd'" \
  "$HAS_SSD_LABEL" "yes" \
  "Gắn nhãn bằng lệnh: kubectl label node node01 hardware=ssd"

# 2. Kiểm tra Pod ssd-app tồn tại và đang chạy (Running)
POD_STATUS=$(kubectl get pod ssd-app -o jsonpath='{.status.phase}' 2>/dev/null)
check "Pod 'ssd-app' tồn tại và đang hoạt động (Running)" \
  "$POD_STATUS" "Running" \
  "Triển khai pod bằng lệnh: kubectl apply -f /root/k8s-lab/ssd-pod.yaml"

# 3. Kiểm tra Pod ssd-app được điều phối chính xác lên node01
SCHEDULED_NODE=$(kubectl get pod ssd-app -o jsonpath='{.spec.nodeName}' 2>/dev/null)
check "Pod 'ssd-app' được điều phối chính xác về Worker Node 'node01'" \
  "$SCHEDULED_NODE" "node01" \
  "Kiểm tra lại khai báo nodeSelector trong ssd-pod.yaml"

# 4. Kiểm tra bài tập: Nhãn environment đã được gỡ khỏi node01
HAS_ENV_LABEL="no"
if kubectl get nodes -l environment=production --no-headers 2>/dev/null | grep -q "node01"; then
  HAS_ENV_LABEL="yes"
fi

check "Bài tập: Nhãn 'environment' đã được gỡ bỏ an toàn khỏi 'node01'" \
  "$HAS_ENV_LABEL" "no" \
  "Chạy lệnh gỡ nhãn: kubectl label node node01 environment-"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Bạn đã nắm vững cơ chế quản lý nhãn và định tuyến Pod."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
