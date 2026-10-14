#!/bin/bash
set -e

DASH_FILE="/root/grafana-lab/dashboards/application-red-dashboard.json"

# 1. Kiem tra tep schema ton tai
if [ ! -f "$DASH_FILE" ]; then
  echo "Loi: Chua tim thay tep Dashboard Schema: $DASH_FILE!"
  echo "Goi y: Hay luu tep application-red-dashboard.json theo huong dan o Buoc 3."
  exit 1
fi

# 2. Kiem tra noi dung co bieu thuc RED va Histogram
if ! grep -q "histogram_quantile" "$DASH_FILE" || ! grep -q "active_users_total" "$DASH_FILE"; then
  echo "Loi: Tep $DASH_FILE chua chua cac panel hoac bieu thuc PromQL do RED (histogram_quantile, active_users_total)!"
  exit 1
fi

# 3. Kiem tra Grafana REST API da nap dashboard thanh cong chua
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload > /dev/null 2>&1 || true
sleep 1

DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/ecommerce-app-red 2>/dev/null || echo "{}")
DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  docker restart grafana > /dev/null 2>&1
  sleep 4
  DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/ecommerce-app-red 2>/dev/null || echo "{}")
  DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")
fi

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  echo "Loi: Grafana chua nạp duoc Dashboard voi UID 'ecommerce-app-red'!"
  echo "Kiem tra lai tep json trong thu muc /root/grafana-lab/dashboards/."
  exit 1
fi

echo "[XAC THUC THANH CONG] Grafana da nap thanh cong Dashboard ung dung RED: '$DASH_TITLE' (UID: ecommerce-app-red)!"
exit 0
