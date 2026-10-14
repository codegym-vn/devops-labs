#!/bin/bash
set -e

# 1. Kiem tra container prometheus dang chay
PROM_STATUS=$(docker inspect -f '{{.State.Running}}' prometheus 2>/dev/null || echo "false")
if [ "$PROM_STATUS" != "true" ]; then
  echo "Loi: Container 'prometheus' chua duoc khoi chay hoac khong o trang thai running!"
  exit 1
fi

# 2. Kiem tra tep cau hinh prometheus.yml
CONFIG_FILE="/root/prometheus-lab/prometheus.yml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Loi: Khong tim thay tep cau hinh $CONFIG_FILE!"
  exit 1
fi

# 3. Kiem tra Prometheus API phan hoi
UP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy || echo "000")
if [ "$UP_CODE" != "200" ]; then
  echo "Loi: Prometheus khong phan hoi HTTP 200 tai endpoint /-/healthy (Ma: $UP_CODE)!"
  exit 1
fi

# 4. Kiem tra cac Targets deu o trang thai 'up'
TARGETS_JSON=$(curl -s http://localhost:9090/api/v1/targets || echo "{}")

NODE_UP=$(echo "$TARGETS_JSON" | jq -r '.data.activeTargets[] | select(.labels.job == "node") | .health' 2>/dev/null || echo "")
REDIS_UP=$(echo "$TARGETS_JSON" | jq -r '.data.activeTargets[] | select(.labels.job == "redis") | .health' 2>/dev/null || echo "")

if [ "$NODE_UP" != "up" ]; then
  echo "Loi: Target job 'node' chua o trang thai 'up' (Hien tai: '$NODE_UP')!"
  exit 1
fi

if [ "$REDIS_UP" != "up" ]; then
  echo "Loi: Target job 'redis' chua o trang thai 'up' (Hien tai: '$REDIS_UP')!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Prometheus da scrape thanh cong ca 3 nguon: prometheus, node-exporter va redis-exporter!"
exit 0
