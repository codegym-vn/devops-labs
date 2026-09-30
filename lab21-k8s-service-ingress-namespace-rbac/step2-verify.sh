#!/bin/bash

# 1. Kiểm tra Service order-service tồn tại
if ! kubectl get svc order-service > /dev/null 2>&1; then
  echo "Chua tim thay Service 'order-service'. Vui long khoi tao theo dung yeu cau!"
  exit 1
fi

# 2. Kiểm tra type ClusterIP
SVC_TYPE=$(kubectl get svc order-service -o jsonpath='{.spec.type}')
if [ "$SVC_TYPE" != "ClusterIP" ]; then
  echo "Loai Service phai la 'ClusterIP' (Hien tai: $SVC_TYPE)!"
  exit 1
fi

# 3. Kiểm tra Port và TargetPort
PORT=$(kubectl get svc order-service -o jsonpath='{.spec.ports[0].port}')
TARGET_PORT=$(kubectl get svc order-service -o jsonpath='{.spec.ports[0].targetPort}')

if [ "$PORT" != "80" ] || [ "$TARGET_PORT" != "8080" ]; then
  echo "Cau hinh cong chua dung: port=$PORT (yeu cau: 80), targetPort=$TARGET_PORT (yeu cau: 8080)!"
  exit 1
fi

# 4. Kiểm tra selector app=order-app
SELECTOR=$(kubectl get svc order-service -o jsonpath='{.spec.selector.app}')
if [ "$SELECTOR" != "order-app" ]; then
  echo "Bo chon selector khong khop voi nhan 'app=order-app' (Hien tai: app=$SELECTOR)!"
  exit 1
fi

echo "Chuc mung! Service 'order-service' da duoc cau hinh ClusterIP voi day du cong va bo chon chinh xac."
exit 0
