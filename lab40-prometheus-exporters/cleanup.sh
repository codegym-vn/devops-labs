#!/bin/bash
# Script don dep tai nguyen sau khi hoan thanh Lab 40

echo "Dang dung va thu hoi tai nguyen Lab 40..."

# 1. Dung va xoa cac Docker container
docker rm -f node-exporter redis redis-exporter prometheus > /dev/null 2>&1 || true

# 2. Xoa cac file tam
rm -f /tmp/background-finished

echo "[OK] Da don dep hoan tat! Toan bo container cua Lab 40 da duoc thu hoi."
