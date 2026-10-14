#!/bin/bash
echo "Dang don dep moi truong Lab 43..."

# 1. Dung cac container
docker rm -f node-exporter prometheus alertmanager > /dev/null 2>&1 || true

# 2. Dung cac tien trinh chay ngam
pkill -f "server.py" > /dev/null 2>&1 || true
pkill -f "webhook_receiver.py" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 3. Xoa file tam
rm -f /tmp/background-finished /usr/local/bin/promtool /usr/local/bin/amtool

echo "[HOAN TAT] Don dep moi truong Lab 43 thanh cong!"
