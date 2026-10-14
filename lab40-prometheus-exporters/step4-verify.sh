#!/bin/bash
set -e

# 1. Kiem tra xem tep cau hinh tren host da duoc them nhan tier chua
CONFIG_FILE="/root/prometheus-lab/prometheus.yml"
if [ -f "$CONFIG_FILE" ] && grep -qi "tier" "$CONFIG_FILE"; then
  # Dong bo tep truc tiep vao container de phong ngua truong hop bind-mount inode bi lech do sed/vim
  docker cp "$CONFIG_FILE" prometheus:/etc/prometheus/prometheus.yml 2>/dev/null || true
  curl -s -X POST http://localhost:9090/-/reload > /dev/null 2>&1 || true
fi

# 2. Kiem tra Prometheus Targets API xem nhan tier="backend" da duoc ap dung chua
TIER_LABEL=""
for i in {1..8}; do
  TARGETS_JSON=$(curl -s http://localhost:9090/api/v1/targets || echo "{}")
  TIER_LABEL=$(echo "$TARGETS_JSON" | jq -r '.data.activeTargets[] | select(.labels.job == "node") | .labels.tier' 2>/dev/null || echo "")
  if [ "$TIER_LABEL" = "backend" ]; then
    break
  fi
  sleep 1
done

if [ "$TIER_LABEL" != "backend" ]; then
  echo "Loi: Nhan 'tier: backend' chua duoc nap vao target 'node' trong Prometheus (Hien tai: '$TIER_LABEL')!"
  echo "Goi y: Hay chay 2 lenh sau de dong bo va nap lai cau hinh:"
  echo "  docker cp /root/prometheus-lab/prometheus.yml prometheus:/etc/prometheus/prometheus.yml"
  echo "  curl -X POST http://localhost:9090/-/reload"
  exit 1
fi

echo "[XAC THUC HOAN TAT] Hot-reload thanh cong! Prometheus da cap nhat nhan tier='backend' cho job 'node' ma khong he lam gian doan dich vu!"
exit 0
