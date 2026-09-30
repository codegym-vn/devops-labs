#!/bin/bash

# 1. Kiểm tra PVC app-data-pvc tồn tại trong default namespace
if ! kubectl get pvc app-data-pvc > /dev/null 2>&1; then
  echo "Chua tim thay PersistentVolumeClaim 'app-data-pvc' trong namespace default!"
  exit 1
fi

# 2. Kiểm tra dung lượng yêu cầu 500Mi
STORAGE_REQ=$(kubectl get pvc app-data-pvc -o jsonpath='{.spec.resources.requests.storage}')
if [ "$STORAGE_REQ" != "500Mi" ]; then
  echo "Dung luong yeu cau phai la 500Mi (Hien tai: $STORAGE_REQ)!"
  exit 1
fi

# 3. Kiểm tra trạng thái Bound
STATUS=$(kubectl get pvc app-data-pvc -o jsonpath='{.status.phase}')
if [ "$STATUS" != "Bound" ]; then
  echo "PVC 'app-data-pvc' chua dat trang thai Bound (Hien tai: $STATUS). Vui long kiem tra StorageClass!"
  exit 1
fi

echo "Chuc mung! PersistentVolumeClaim 'app-data-pvc' da duoc cap phat dong thanh cong va dat trang thai Bound."
exit 0
