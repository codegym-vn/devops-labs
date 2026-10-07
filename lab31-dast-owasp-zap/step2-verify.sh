#!/bin/bash
set -e

cd /root/dast-target-app

# 1. Kiem tra tep bao cao JSON va HTML cua ZAP
if [ ! -f zap-initial-report.json ] || [ ! -f zap-initial-report.html ]; then
  echo "Loi: Tep bao cao zap-initial-report.json hoac zap-initial-report.html chua duoc tao!"
  exit 1
fi

ALERTS=$(jq -r '.site[0].alerts | length' zap-initial-report.json 2>/dev/null || echo "0")
if [ "$ALERTS" -lt 1 ]; then
  echo "Loi: Bao cao ZAP khong chua du lieu canh bao lo hong DAST!"
  exit 1
fi

echo "OWASP ZAP Baseline Scan da hoan thanh va tao bao cao hop le ($ALERTS canh bao)!"
exit 0
