#!/bin/bash
# Script don dep tai nguyen sau khi hoan thanh Lab 39

echo "Dang dung va thu hoi tai nguyen Lab 39..."

# 1. Dung cac tien trinh Node.js va Traffic Generator
pkill -f "order-service.js" > /dev/null 2>&1 || true
pkill -f "payment-service.js" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 2. Xoa cac Docker container
docker rm -f jaeger loki nginx-gateway fluent-bit > /dev/null 2>&1 || true

# 3. Don dep cac file tam
rm -f /tmp/background-finished

echo "[OK] Da don dep hoan tat! Toan bo container va tien trinh da duoc thu hoi."
