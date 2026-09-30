#!/bin/bash

# 1. Kiểm tra Ingress app-ingress tồn tại
if ! kubectl get ingress app-ingress > /dev/null 2>&1; then
  echo "Chua tim thay Ingress 'app-ingress' trong namespace default!"
  exit 1
fi

# 2. Kiểm tra quy tắc đường dẫn /store
STORE_PATH=$(kubectl get ingress app-ingress -o jsonpath='{.spec.rules[*].http.paths[?(@.path=="/store")].path}')
if [ -z "$STORE_PATH" ]; then
  echo "Ingress 'app-ingress' chua dinh nghia duong dan '/store'!"
  exit 1
fi

# 3. Kiểm tra backend service
BACKEND_SVC=$(kubectl get ingress app-ingress -o jsonpath='{.spec.rules[*].http.paths[?(@.path=="/store")].backend.service.name}')
BACKEND_PORT=$(kubectl get ingress app-ingress -o jsonpath='{.spec.rules[*].http.paths[?(@.path=="/store")].backend.service.port.number}')

if [ "$BACKEND_SVC" != "order-service" ]; then
  echo "Backend service cho duong dan '/store' phai la 'order-service' (Hien tai: $BACKEND_SVC)!"
  exit 1
fi

if [ "$BACKEND_PORT" -ne 80 ]; then
  echo "Backend port phai la 80 (Hien tai: $BACKEND_PORT)!"
  exit 1
fi

echo "Chuc mung! Ingress 'app-ingress' da duoc cau hinh dinh tuyen tang 7 hoan toan chinh xac."
exit 0
