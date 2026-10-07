#!/bin/bash

# Kiểm tra Deployment web-canary-faulty đã được xóa sạch
if kubectl get deployment web-canary-faulty > /dev/null 2>&1; then
  echo "Deployment 'web-canary-faulty' van dang ton tai! Hay thuc hien rollback bang lenh: kubectl delete -f deployment-canary-faulty.yaml"
  exit 1
fi

# Kiểm tra Deployment web-stable vẫn đang hoạt động ổn định với 4 replicas
READY_REPLICAS=$(kubectl get deployment web-stable -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY_REPLICAS" -ne 4 ]; then
  echo "Deployment 'web-stable' chua duy tri du 4 ban sao san sang sau rollback (Hien tai: $READY_REPLICAS/4)."
  exit 1
fi

echo "Chuc mung! Ban da thuc hien co che Rollback khan cap thanh cong va he thong da tro lai trang thai on dinh tuyet doi."
exit 0
