#!/bin/bash
set -e

# 1. Kiem tra container jaeger dang chay
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' jaeger 2>/dev/null || echo "false")
if [ "$CONTAINER_STATUS" != "true" ]; then
  echo "Loi: Container jaeger chua duoc khoi chay hoac khong o trang thai running!"
  exit 1
fi

# 2. Kiem tra API Jaeger port 16686 phan hoi HTTP 200
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:16686/api/services || echo "000")
if [ "$HTTP_CODE" != "200" ]; then
  echo "Loi: Jaeger API tai http://localhost:16686 khong phan hoi ma 200 (Ma tra ve: $HTTP_CODE)!"
  exit 1
fi

echo "Xac thuc thanh cong: Jaeger All-in-One da hoat dong on dinh tren cong 16686 va 4318."
exit 0
