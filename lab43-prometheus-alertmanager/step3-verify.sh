#!/bin/bash
set -e

AM_FILE="/root/alerting-lab/alertmanager.yml"

# 1. Kiem tra tep alertmanager.yml co inhibit_rules
if [ ! -f "$AM_FILE" ]; then
  echo "Loi: Chua tim thay tep cau hinh $AM_FILE!"
  exit 1
fi

if ! grep -q "inhibit_rules:" "$AM_FILE"; then
  echo "Loi: Tep $AM_FILE chua dinh nghia quy tac kìm ham 'inhibit_rules'!"
  exit 1
fi

if ! amtool check-config "$AM_FILE" > /dev/null 2>&1; then
  echo "Loi: Cu phap cua tep $AM_FILE khong hop le theo amtool!"
  exit 1
fi

# 2. Kiem tra co Silence dang active trong Alertmanager
SILENCES_RESP=$(curl -s http://localhost:9093/api/v2/silences 2>/dev/null || echo "[]")
ACTIVE_SILENCES=$(echo "$SILENCES_RESP" | jq -r '[.[] | select(.status.state=="active")] | length' 2>/dev/null || echo "0")

if [ "$ACTIVE_SILENCES" -eq 0 ]; then
  echo "Loi: Chua tim thay Silence nao dang o trang thai 'active' trong Alertmanager!"
  echo "Goi y: Hay chay lenh 'amtool silence add ...' theo huong dan o Buoc 3."
  exit 1
fi

SILENCE_AUTHOR=$(echo "$SILENCES_RESP" | jq -r '[.[] | select(.status.state=="active")][0].createdBy' 2>/dev/null || echo "unknown")
echo "[XAC THUC THANH CONG] Alertmanager da kich hoat Inhibition Rules va dang ap dung $ACTIVE_SILENCES Silence (Tao boi: $SILENCE_AUTHOR)!"
exit 0
