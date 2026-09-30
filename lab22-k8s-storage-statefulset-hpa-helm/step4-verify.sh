#!/bin/bash

# 1. Kiểm tra Helm release web-release tồn tại
if ! helm status web-release > /dev/null 2>&1; then
  echo "Chua tim thay ban phat hanh Helm 'web-release'!"
  exit 1
fi

# 2. Kiểm tra trạng thái deployed
HELM_STATUS=$(helm status web-release -o json 2>/dev/null | jq -r '.info.status')
if [ "$HELM_STATUS" != "deployed" ]; then
  echo "Ban phat hanh 'web-release' chua o trang thai deployed (Hien tai: $HELM_STATUS)!"
  exit 1
fi

# 3. Kiểm tra revision >= 2
REVISION=$(helm status web-release -o json 2>/dev/null | jq -r '.version')
if [ "$REVISION" -lt 2 ]; then
  echo "Ban phat hanh 'web-release' chua duoc upgrade len revision 2 (Hien tai: revision $REVISION)!"
  exit 1
fi

# 4. Kiểm tra deployment có đúng 3 bản sao
DEP_NAME=$(kubectl get deployment -l 'app.kubernetes.io/instance=web-release' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$DEP_NAME" ]; then
  echo "Khong tim thay Deployment do 'web-release' quan ly!"
  exit 1
fi

REPLICAS=$(kubectl get deployment "$DEP_NAME" -o jsonpath='{.spec.replicas}')
READY_REPLICAS=$(kubectl get deployment "$DEP_NAME" -o jsonpath='{.status.readyReplicas}')

if [ "$REPLICAS" -ne 3 ] || [ "$READY_REPLICAS" -ne 3 ]; then
  echo "So luong ban sao cua Deployment chua dat 3/3 san sang (Replicas: $READY_REPLICAS/$REPLICAS)!"
  exit 1
fi

echo "Xuat sac! Ban phat hanh Helm 'web-release' da duoc nang cap len revision $REVISION voi 3 ban sao hoat dong on dinh."
exit 0
