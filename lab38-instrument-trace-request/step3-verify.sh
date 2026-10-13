#!/bin/bash
set -e

# 1. Kiem tra payment-service tren cong 8081
PAY_HEALTH=$(curl -s http://localhost:8081/health | jq -r '.status' 2>/dev/null || echo "DOWN")
if [ "$PAY_HEALTH" != "UP" ]; then
  echo "Loi: payment-service chua hoat dong tren cong 8081!"
  exit 1
fi

# 2. Kiem tra order-service tren cong 3000
ORDER_HEALTH=$(curl -s http://localhost:3000/health | jq -r '.status' 2>/dev/null || echo "DOWN")
if [ "$ORDER_HEALTH" != "UP" ]; then
  echo "Loi: order-service chua hoat dong tren cong 3000!"
  exit 1
fi

# 3. Kiem tra xem co Trace nao chua dong thoi ca 2 service (order-service va payment-service)
HAS_BOTH=$(curl -s "http://localhost:16686/api/traces?service=order-service&limit=10" | jq -r '
  .data[] | 
  select(
    ([.processes[].serviceName] | contains(["order-service"])) and 
    ([.processes[].serviceName] | contains(["payment-service"]))
  ) | .traceID' 2>/dev/null | head -n 1)

if [ -z "$HAS_BOTH" ]; then
  echo "Loi: Chua tim thay Trace nao xau chuoi dong thoi ca order-service va payment-service!"
  echo "Goi y: Hay chay lenh curl goi POST http://localhost:3000/api/orders o buoc 3.3 de tao giao dich lien microservice."
  exit 1
fi

echo "Xac thuc thanh cong: Da tim thay Trace phan tan $HAS_BOTH gom ca order-service va payment-service!"
exit 0
