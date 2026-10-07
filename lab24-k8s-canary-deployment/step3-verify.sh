#!/bin/bash

# Kiểm tra Deployment web-stable tồn tại
if ! kubectl get deployment web-stable > /dev/null 2>&1; then
  echo "Chua tim thay Deployment 'web-stable'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra số lượng replicas cấu hình
SPEC_REPLICAS=$(kubectl get deployment web-stable -o jsonpath='{.spec.replicas}')
if [ "$SPEC_REPLICAS" -ne 4 ]; then
  echo "Deployment 'web-stable' chua duoc scale len dung 4 replicas (Hien tai: $SPEC_REPLICAS)."
  exit 1
fi

# Kiểm tra số lượng Pod Ready
READY_REPLICAS=$(kubectl get deployment web-stable -o jsonpath='{.status.readyReplicas}')
if [ "$READY_REPLICAS" -ne 4 ]; then
  echo "Deployment 'web-stable' chua co du 4 replicas san sang (Ready: $READY_REPLICAS/4)."
  exit 1
fi

# Kiểm tra phiên bản mới v2.0-stable trong cấu hình
ENV_VERSION=$(kubectl get deployment web-stable -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_VERSION")].value}')
if [ "$ENV_VERSION" != "v2.0-stable" ]; then
  echo "Deployment 'web-stable' chua duoc cap nhat len phien ban v2.0-stable (Hien tai: $ENV_VERSION)."
  exit 1
fi

# Kiểm tra Deployment web-canary đã được xóa bỏ
if kubectl get deployment web-canary > /dev/null 2>&1; then
  echo "Deployment 'web-canary' van con ton tai! Hay xoa bo sau khi thang cap (kubectl delete -f deployment-canary.yaml)."
  exit 1
fi

echo "Chuc mung! Qua trinh thang cap (Promotion) len v2.0 va thu hoi Canary da hoan tat xuat sac."
exit 0
