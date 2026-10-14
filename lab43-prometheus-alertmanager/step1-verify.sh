#!/bin/bash
set -e

HOST_RULES="/root/alerting-lab/rules/host_alerts.yml"
APP_RULES="/root/alerting-lab/rules/app_alerts.yml"

# 1. Kiem tra tep rule ton tai
if [ ! -f "$HOST_RULES" ] || [ ! -f "$APP_RULES" ]; then
  echo "Loi: Chua tim thay day du 2 tep rule tai /root/alerting-lab/rules/!"
  echo "Goi y: Hay tao host_alerts.yml va app_alerts.yml theo huong dan."
  exit 1
fi

# 2. Kiem tra cu phap bang promtool
if ! promtool check rules "$HOST_RULES" > /dev/null 2>&1; then
  echo "Loi: Cu phap cua tep $HOST_RULES khong hop le theo promtool!"
  exit 1
fi

if ! promtool check rules "$APP_RULES" > /dev/null 2>&1; then
  echo "Loi: Cu phap cua tep $APP_RULES khong hop le theo promtool!"
  exit 1
fi

# 3. Reload Prometheus
curl -s -X POST http://localhost:9090/-/reload > /dev/null 2>&1 || true
sleep 1

# 4. Kiem tra qua Prometheus API
RULES_RESP=$(curl -s http://localhost:9090/api/v1/rules 2>/dev/null || echo "{}")
RULE_NAMES=$(echo "$RULES_RESP" | jq -r '.data.groups[].rules[].name' 2>/dev/null || echo "")

REQUIRED_RULES=("HostHighCpuLoad" "HostOutOfMemory" "ServiceTargetDown" "ApiHighErrorRate")
for r in "${REQUIRED_RULES[@]}"; do
  if ! echo "$RULE_NAMES" | grep -q "$r"; then
    echo "Loi: Prometheus chua nap duoc quy tac canh bao '$r'!"
    exit 1
  fi
done

TOTAL_COUNT=$(echo "$RULE_NAMES" | wc -w)
echo "[XAC THUC THANH CONG] Prometheus da nap thanh cong $TOTAL_COUNT Alert Rules hop le qua promtool!"
exit 0
