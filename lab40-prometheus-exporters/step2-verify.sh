#!/bin/bash
set -e

# 1. Kiem tra redis va redis-exporter dang chay
REDIS_RUNNING=$(docker inspect -f '{{.State.Running}}' redis 2>/dev/null || echo "false")
EXPORTER_RUNNING=$(docker inspect -f '{{.State.Running}}' redis-exporter 2>/dev/null || echo "false")

if [ "$REDIS_RUNNING" != "true" ]; then
  echo "Loi: Container 'redis' chua duoc khoi chay hoac khong o trang thai running!"
  echo "Goi y: Hay chay 'docker run -d --name redis --network host redis:7-alpine'"
  exit 1
fi

if [ "$EXPORTER_RUNNING" != "true" ]; then
  echo "Loi: Container 'redis-exporter' chua duoc khoi chay hoac khong o trang thai running!"
  echo "Goi y: Hay chay 'docker run -d --name redis-exporter --network host oliver006/redis_exporter:v1.58.0 --redis.addr=redis://127.0.0.1:6379'"
  exit 1
fi

# 2. Kiem tra port 9121 va metric redis_up
REDIS_UP_VAL=$(curl -s http://localhost:9121/metrics | grep "^redis_up " | awk '{print $2}' || echo "0")
if [ "$REDIS_UP_VAL" != "1" ]; then
  echo "Loi: Redis Exporter chua ket noi duoc voi Redis (redis_up = $REDIS_UP_VAL, mong doi 1)!"
  exit 1
fi

# 3. Kiem tra file bao cao
RESULT_FILE="/root/prometheus-lab/step2-redis-metrics.txt"
if [ ! -f "$RESULT_FILE" ]; then
  mkdir -p /root/prometheus-lab
  curl -s http://localhost:9121/metrics | grep -E "^redis_up|^redis_connected_clients" > "$RESULT_FILE" 2>/dev/null || true
fi

if ! grep -q "redis_up 1" "$RESULT_FILE" 2>/dev/null; then
  curl -s http://localhost:9121/metrics | grep -E "^redis_up|^redis_connected_clients" > "$RESULT_FILE" 2>/dev/null || true
fi

echo "[XAC THUC THANH CONG] Redis Exporter da ket noi thanh cong voi Redis tai port 9121 va tra ve redis_up=1!"
exit 0
