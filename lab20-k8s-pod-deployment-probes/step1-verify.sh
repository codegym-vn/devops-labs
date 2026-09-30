#!/bin/bash

# Kiểm tra Pod standalone-worker tồn tại
if ! kubectl get pod standalone-worker > /dev/null 2>&1; then
  echo "Chua tim thay Pod 'standalone-worker'. Vui long khoi tao dung ten yeu cau!"
  exit 1
fi

# Kiểm tra trạng thái Running
STATUS=$(kubectl get pod standalone-worker -o jsonpath='{.status.phase}')
if [ "$STATUS" != "Running" ]; then
  echo "Pod 'standalone-worker' chua o trang thai Running (Hien tai: $STATUS)."
  exit 1
fi

# Kiểm tra Requests và Limits
REQ_CPU=$(kubectl get pod standalone-worker -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
REQ_MEM=$(kubectl get pod standalone-worker -o jsonpath='{.spec.containers[0].resources.requests.memory}')
LIM_MEM=$(kubectl get pod standalone-worker -o jsonpath='{.spec.containers[0].resources.limits.memory}')

if [ "$REQ_CPU" != "50m" ] && [ "$REQ_MEM" != "64Mi" ]; then
  echo "Thieu cau hinh resources.requests (cpu: 50m hoac memory: 64Mi)."
  exit 1
fi

if [ "$LIM_MEM" != "128Mi" ]; then
  echo "Thieu cau hinh resources.limits (memory: 128Mi)."
  exit 1
fi

echo "Chuc mung! Pod 'standalone-worker' da duoc khoi chay voi han muc tai nguyen chinh xac."
exit 0
