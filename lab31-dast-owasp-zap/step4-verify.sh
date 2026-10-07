#!/bin/bash
cd /root/dast-target-app
REPORT=zap-reports/zap-final-report.json

if ! grep -q "require('helmet')" server.js || ! grep -q "app.use(helmet())" server.js; then
  echo "server.js chua tich hop helmet."
  exit 1
fi

HEADERS=$(curl -s -I http://localhost:3000)
if ! echo "$HEADERS" | grep -qi '^x-frame-options'; then
  echo "Ung dung chua tra ve X-Frame-Options. Hay khoi dong lai node server.js."
  exit 1
fi
if echo "$HEADERS" | grep -qi '^x-powered-by'; then
  echo "Ung dung van tra ve X-Powered-By."
  exit 1
fi

if [ ! -s "$REPORT" ]; then
  echo "Chua co $REPORT. Hay chay lai ZAP o muc 3."
  exit 1
fi

for id in 10020 10021 10037 10038; do
  if jq -e --arg id "$id" '.site[0].alerts[] | select(.pluginid == $id)' "$REPORT" > /dev/null 2>&1; then
    echo "Bao cao cuoi van con canh bao $id."
    exit 1
  fi
done

echo "Buoc 4 hoan thanh"
exit 0
