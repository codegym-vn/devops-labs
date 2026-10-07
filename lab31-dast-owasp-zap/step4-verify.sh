#!/bin/bash
set -e

cd /root/dast-target-app

# 1. Kiem tra code da tich hop helmet
if ! grep -q "require('helmet')" server.js; then
  echo "Loi: server.js chua tich hop thu vien helmet!"
  exit 1
fi

# 2. Kiem tra HTTP Headers thuc te cua ung dung
HEADERS=$(curl -s -I http://localhost:3000)
if ! echo "$HEADERS" | grep -qi "x-frame-options"; then
  echo "Loi: Ung dung web van chua tra ve header X-Frame-Options!"
  exit 1
fi

# 3. Kiem tra tep bao cao zap-final-report.json
if [ ! -f zap-final-report.json ]; then
  echo "Loi: Tep zap-final-report.json chua duoc tao!"
  exit 1
fi

ALERTS=$(jq -r '.site[0].alerts | length' zap-final-report.json 2>/dev/null || echo "-1")
if [ "$ALERTS" -ne 0 ]; then
  echo "Loi: zap-final-report.json van con chua $ALERTS canh bao lo hong!"
  exit 1
fi

echo "Nghiem thu an ninh DAST thanh cong voi 0 canh bao!"
exit 0
