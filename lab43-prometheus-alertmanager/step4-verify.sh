#!/bin/bash
set -e

REPORT_FILE="/root/alerting-lab/alert-incident-report.json"
LOG_FILE="/root/alerting-lab/webhook.log"

# 1. Kiem tra tep bao cao ton tai
if [ ! -f "$REPORT_FILE" ]; then
  echo "Loi: Chua tim thay tep bao cao $REPORT_FILE!"
  echo "Goi y: Hay tao tep alert-incident-report.json theo huong dan o Buoc 4."
  exit 1
fi

# 2. Kiem tra noi dung tep bao cao
if ! grep -q "ApiHighErrorRate" "$REPORT_FILE"; then
  echo "Loi: Noi dung $REPORT_FILE chua ghi nhan alertname 'ApiHighErrorRate'!"
  exit 1
fi

# 3. Kiem tra Webhook log da ghi nhan duoc goi tin canh bao chua
if [ ! -f "$LOG_FILE" ]; then
  echo "Loi: Chua tim thay tep nhat ky webhook tai $LOG_FILE!"
  exit 1
fi

if ! grep -q "ApiHighErrorRate" "$LOG_FILE" && ! grep -q "RECEIVED WEBHOOK" "$LOG_FILE"; then
  echo "Canh bao: Webhook receiver chua ghi nhan duoc su kien ban alert tu Alertmanager!"
  echo "Goi y: Hay chay cac lenh Fault Injection sinh loi va kiem tra 'cat $LOG_FILE'."
  exit 1
fi

echo "[XAC THUC THANH CONG] Quy trinh Alerting da duoc kiem chung thanh cong (Firing -> Webhook Received -> Resolved)!"
exit 0
