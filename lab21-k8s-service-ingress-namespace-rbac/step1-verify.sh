#!/bin/bash

# 1. Kiểm tra Namespace staging tồn tại
if ! kubectl get namespace staging > /dev/null 2>&1; then
  echo "Chua tim thay Namespace 'staging'. Vui long khoi tao theo dung yeu cau!"
  exit 1
fi

# 2. Kiểm tra Pod staging-web tồn tại trong namespace staging
if ! kubectl get pod staging-web -n staging > /dev/null 2>&1; then
  echo "Chua tim thay Pod 'staging-web' trong Namespace 'staging'!"
  exit 1
fi

# 3. Kiểm tra trạng thái Running
STATUS=$(kubectl get pod staging-web -n staging -o jsonpath='{.status.phase}')
if [ "$STATUS" != "Running" ]; then
  echo "Pod 'staging-web' chua o trang thai Running (Hien tai: $STATUS)."
  exit 1
fi

echo "Chuc mung! Namespace 'staging' va Pod 'staging-web' da duoc khoi tao va chay on dinh."
exit 0
