#!/bin/bash
echo "Dang don dep moi truong Lab 42..."

# 1. Dung cac container
docker rm -f node-exporter prometheus grafana > /dev/null 2>&1 || true

# 2. Kill cac tien trinh chay ngam
pkill -f "server.py" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 3. Xoa file tam
rm -f /tmp/background-finished

echo "[HOAN TAT] Don dep moi truong thanh cong!"
