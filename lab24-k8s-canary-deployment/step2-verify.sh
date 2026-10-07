#!/bin/bash

# Kiểm tra Deployment web-canary tồn tại
if ! kubectl get deployment web-canary > /dev/null 2>&1; then
  echo "Chua tim thay Deployment 'web-canary'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra số lượng replicas cấu hình
SPEC_REPLICAS=$(kubectl get deployment web-canary -o jsonpath='{.spec.replicas}')
if [ "$SPEC_REPLICAS" -ne 1 ]; then
  echo "Deployment 'web-canary' chua duoc cau hinh 1 replica (Hien tai: $SPEC_REPLICAS)."
  exit 1
fi

# Kiểm tra trạng thái Ready của Pod Canary
READY_REPLICAS=$(kubectl get deployment web-canary -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" -ne 1 ]; then
  echo "Pod 'web-canary' chua san sang (Ready: $READY_REPLICAS/1)."
  exit 1
fi

# Kiểm tra tổng số Endpoints của Service web-service
EP_COUNT=$(kubectl get endpoints web-service -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
if [ "$EP_COUNT" -ne 4 ]; then
  echo "Service 'web-service' phai co dung 4 Endpoints (3 stable + 1 canary). Hien tai: $EP_COUNT."
  exit 1
fi

echo "Chuc mung! Deployment 'web-canary' da trien khai thanh cong va Service da nhan du 4 Endpoints."
exit 0
