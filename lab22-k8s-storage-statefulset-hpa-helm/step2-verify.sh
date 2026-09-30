#!/bin/bash

# 1. Kiểm tra StatefulSet db-cluster tồn tại
if ! kubectl get statefulset db-cluster > /dev/null 2>&1; then
  echo "Chua tim thay StatefulSet 'db-cluster' trong default namespace!"
  exit 1
fi

# 2. Kiểm tra số lượng replicas cấu hình
REPLICAS=$(kubectl get statefulset db-cluster -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -ne 3 ]; then
  echo "StatefulSet 'db-cluster' chua duoc scale len dung 3 ban sao (Hien tai: $REPLICAS)!"
  exit 1
fi

# 3. Kiểm tra Pod db-cluster-2 ở trạng thái Running
POD_STATUS=$(kubectl get pod db-cluster-2 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
  echo "Pod 'db-cluster-2' chua o trang thai Running (Hien tai: $POD_STATUS)!"
  exit 1
fi

# 4. Kiểm tra PVC db-store-db-cluster-2 ở trạng thái Bound
PVC_STATUS=$(kubectl get pvc db-store-db-cluster-2 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" != "Bound" ]; then
  echo "PVC 'db-store-db-cluster-2' chua dat trang thai Bound (Hien tai: $PVC_STATUS)!"
  exit 1
fi

echo "Chuc mung! StatefulSet 'db-cluster' da duoc mo rong len 3 ban sao voi day du Pod va PVC tu dong sinh thanh cong."
exit 0
