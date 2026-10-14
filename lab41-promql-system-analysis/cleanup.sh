#!/bin/bash
# Script don dep tai nguyen sau khi hoan thanh Lab 41

echo "Dang dung va thu hoi tai nguyen Lab 41..."

# 1. Dung tien trinh Node.js va Traffic Generator
pkill -f "server.js" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 2. Xoa cac Docker container
docker rm -f node-exporter prometheus > /dev/null 2>&1 || true

# 3. Xoa file tam
rm -f /tmp/background-finished

echo "[OK] Da don dep hoan tat! Toan bo container va tien trinh Lab 41 da duoc thu hoi."
