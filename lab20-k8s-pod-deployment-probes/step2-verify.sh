#!/bin/bash

# Kiểm tra Deployment web-deploy tồn tại
if ! kubectl get deployment web-deploy > /dev/null 2>&1; then
  echo "Chua tim thay Deployment 'web-deploy'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra số lượng replicas cấu hình
SPEC_REPLICAS=$(kubectl get deployment web-deploy -o jsonpath='{.spec.replicas}')
if [ "$SPEC_REPLICAS" -ne 2 ]; then
  echo "Deployment 'web-deploy' chua duoc scale ve dung 2 ban sao (Hien tai: $SPEC_REPLICAS)."
  exit 1
fi

# Kiểm tra số lượng Pod sẵn sàng
READY_REPLICAS=$(kubectl get deployment web-deploy -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" -ne 2 ]; then
  echo "Deployment 'web-deploy' chua co du 2 ban sao san sang (Ready: $READY_REPLICAS/2)."
  exit 1
fi

echo "Chuc mung! Deployment 'web-deploy' da duoc thu hep quy mo ve dung 2 ban sao hoat dong on dinh."
exit 0
