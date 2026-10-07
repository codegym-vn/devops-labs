#!/bin/bash

# Kiểm tra Service web-service tồn tại
if ! kubectl get svc web-service > /dev/null 2>&1; then
  echo "Chua tim thay Service 'web-service'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra Deployment web-stable tồn tại
if ! kubectl get deployment web-stable > /dev/null 2>&1; then
  echo "Chua tim thay Deployment 'web-stable'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra số lượng replicas cấu hình
SPEC_REPLICAS=$(kubectl get deployment web-stable -o jsonpath='{.spec.replicas}')
if [ "$SPEC_REPLICAS" -ne 3 ]; then
  echo "Deployment 'web-stable' chua duoc cau hinh dung 3 replicas (Hien tai: $SPEC_REPLICAS)."
  exit 1
fi

# Kiểm tra số lượng Pod sẵn sàng
READY_REPLICAS=$(kubectl get deployment web-stable -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" -ne 3 ]; then
  echo "Deployment 'web-stable' chua co du 3 replicas o trang thai Ready (Hien tai: $READY_REPLICAS/3)."
  exit 1
fi

# Kiểm tra số lượng Endpoints của web-service
EP_COUNT=$(kubectl get endpoints web-service -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
if [ "$EP_COUNT" -ne 3 ]; then
  echo "Service 'web-service' chua nhan du 3 IP endpoints tu web-stable (Hien tai: $EP_COUNT)."
  exit 1
fi

echo "Chuc mung! Service va Deployment 'web-stable' (3 replicas) da hoat dong chinh xac."
exit 0
