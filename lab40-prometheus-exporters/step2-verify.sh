#!/bin/bash
set -e

# 1. Kiem tra redis va redis-exporter dang chay
REDIS_RUNNING=$(docker inspect -f '{{.State.Running}}' redis 2>/dev/null || echo "false")
EXPORTER_RUNNING=$(docker inspect -f '{{.State.Running}}' redis-exporter 2>/dev/null || echo "false")

if [ "$REDIS_RUNNING" != "true" ]; then
  echo "Loi: Container 'redis' chua duoc khoi chay hoac khong o trang thai running!"
  exit 1
fi

if [ "$EXPORTER_RUNNING" != "true" ]; then
  echo "Loi: Container 'redis-exporter' chua duoc khoi chay hoac khong o trang thai running!"
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
  echo "Loi: Chua tim thay file $RESULT_FILE!"
  exit 1
fi

if ! grep -q "redis_up 1" "$RESULT_FILE"; then
  echo "Loi: File $RESULT_FILE chua co metric 'redis_up 1'!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Redis Exporter da ket noi thanh cong voi Redis tai port 9121 va tra ve redis_up=1!"
exit 0
