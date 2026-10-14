#!/bin/bash
set -e

DASH_FILE="/root/grafana-lab/dashboards/production-system-overview.json"

# 1. Kiem tra tep schema ton tai
if [ ! -f "$DASH_FILE" ]; then
  echo "Loi: Chua tim thay tep Dashboard Schema: $DASH_FILE!"
  echo "Goi y: Hay luu tep production-system-overview.json theo huong dan o Buoc 4."
  exit 1
fi

# 2. Kiem tra noi dung co khai bao templating variable
if ! grep -q "templating" "$DASH_FILE" || ! grep -q "label_values(http_requests_total, path)" "$DASH_FILE"; then
  echo "Loi: Tep $DASH_FILE chua chua khai bao Dynamic Templating voi bien 'path'!"
  exit 1
fi

# 3. Kiem tra Grafana REST API da nap dashboard thanh cong chua
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload > /dev/null 2>&1 || true
sleep 1

DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/prod-system-overview 2>/dev/null || echo "{}")
DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  docker restart grafana > /dev/null 2>&1
  sleep 4
  DASH_RESP=$(curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/prod-system-overview 2>/dev/null || echo "{}")
  DASH_TITLE=$(echo "$DASH_RESP" | jq -r '.dashboard.title' 2>/dev/null || echo "")
fi

if [ -z "$DASH_TITLE" ] || [ "$DASH_TITLE" = "null" ]; then
  echo "Loi: Grafana chua nap duoc Dashboard voi UID 'prod-system-overview'!"
  echo "Kiem tra lai tep json trong thu muc /root/grafana-lab/dashboards/."
  exit 1
fi

VAR_NAME=$(echo "$DASH_RESP" | jq -r '.dashboard.templating.list[0].name' 2>/dev/null || echo "")
if [ "$VAR_NAME" != "path" ]; then
  echo "Loi: Bien templating chua duoc dinh nghia chinh xac ten 'path' trong dashboard schema!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Grafana da nap thanh cong Dashboard Production voi Dynamic Templating: '$DASH_TITLE' (Bien: $VAR_NAME)!"
exit 0
