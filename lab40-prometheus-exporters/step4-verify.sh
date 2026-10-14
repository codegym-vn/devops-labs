#!/bin/bash
set -e

# 1. Kiem tra Prometheus Targets API xem nhan tier="backend" da duoc ap dung chua (Vong lap cho cap nhat)
TIER_LABEL=""
for i in {1..5}; do
  TARGETS_JSON=$(curl -s http://localhost:9090/api/v1/targets || echo "{}")
  TIER_LABEL=$(echo "$TARGETS_JSON" | jq -r '.data.activeTargets[] | select(.labels.job == "node") | .labels.tier' 2>/dev/null || echo "")
  if [ "$TIER_LABEL" = "backend" ]; then
    break
  fi
  sleep 1
done

if [ "$TIER_LABEL" != "backend" ]; then
  echo "Loi: Nhan 'tier: backend' chua duoc nap vao target 'node' trong Prometheus (Hien tai: '$TIER_LABEL')!"
  echo "Goi y: Hay kiem tra lai prometheus.yml va kich hoat hot-reload bang 'curl -X POST http://localhost:9090/-/reload'."
  exit 1
fi

echo "[XAC THUC HOAN TAT] Hot-reload thanh cong! Prometheus da cap nhat nhan tier='backend' cho job 'node' ma khong he lam gian doan dich vu!"
exit 0
