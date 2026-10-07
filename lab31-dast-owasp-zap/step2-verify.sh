#!/bin/bash
DIR=/root/dast-target-app/zap-reports

if [ ! -s "$DIR/zap-initial-report.json" ] || [ ! -s "$DIR/zap-initial-report.html" ]; then
  echo "Chua co bao cao zap-initial-report.json/html trong $DIR. Hay chay lenh ZAP o muc 2."
  exit 1
fi

if ! grep -q '"pluginid"' "$DIR/zap-initial-report.json"; then
  echo "Bao cao ZAP khong co canh bao nao. Kiem tra ung dung co dang chay o cong 3000 khong."
  exit 1
fi

echo "Buoc 2 hoan thanh"
exit 0
