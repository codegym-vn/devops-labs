#!/bin/bash
set -e

# 1. Kiem tra dich vu order-service tren cong 3000
HEALTH_STATUS=$(curl -s http://localhost:3000/health | jq -r '.status' 2>/dev/null || echo "DOWN")
if [ "$HEALTH_STATUS" != "UP" ]; then
  echo "Loi: order-service chua chay tren cong 3000 hoac phan hoi health check that bai!"
  exit 1
fi

# 2. Kiem tra trace cua order-service da ton tai trong Jaeger
TRACE_COUNT=$(curl -s "http://localhost:16686/api/traces?service=order-service&limit=1" | jq '.data | length' 2>/dev/null || echo "0")
if [ "$TRACE_COUNT" -lt 1 ]; then
  echo "Loi: Chua tim thay Trace nao cua order-service trong Jaeger! Hay gui thu nghiem request POST /api/orders."
  exit 1
fi

echo "Xac thuc thanh cong: order-service da chay va da day trace thanh cong ve Jaeger."
exit 0
