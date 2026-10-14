#!/bin/bash
set -e

PROV_FILE="/root/grafana-lab/provisioning/dashboards/dashboard-provider.yml"
DASH_FILE="/root/grafana-lab/dashboards/infrastructure-dashboard.json"

# 1. Kiem tra tep provider ton tai
if [ ! -f "$PROV_FILE" ]; then
  echo "Loi: Chua tim thay tep Dashboard Provider: $PROV_FILE!"
  echo "Goi y: Hay tao tep theo huong dan o Buoc 2."
  exit 1
fi

# 2. Kiem tra tep schema dashboard ton tai
if [ ! -f "$DASH_FILE" ]; then
  echo "Loi: Chua tim thay tep Dashboard Schema: $DASH_FILE!"
  echo "Goi y: Hay luu tep infrastructure-dashboard.json theo huong dan."
  exit 1
fi

# 3. Kiem tra cu phap co chua gauge va node_cpu_seconds_total
if ! grep -q "gauge" "$DASH_FILE" || ! grep -q "node_cpu_seconds_total" "$DASH_FILE"; then
  echo "Loi: Tep $DASH_FILE chua chua cac panel Gauge hoac bieu thuc PromQL do CPU/RAM!"
  exit 1
fi

# 4. Kiem tra Grafana REST API da nap dashboard thanh cong chua
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload > /dev/null 2>&1 || true
sleep 1

DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/linux-host-infra 2>/dev/null || echo "{}")
DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  # Thu reload bang docker restart
  docker restart grafana > /dev/null 2>&1
  sleep 4
  DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/linux-host-infra 2>/dev/null || echo "{}")
  DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")
fi

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  echo "Loi: Grafana chua nạp duoc Dashboard voi UID 'linux-host-infra'!"
  echo "Kiem tra lai noi dung trong thu muc provisioning va dashboards."
  exit 1
fi

echo "[XAC THUC THANH CONG] Grafana da nap thanh cong Dashboard ha tang: '$DASH_TITLE' (UID: linux-host-infra)!"
exit 0
