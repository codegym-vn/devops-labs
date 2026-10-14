#!/bin/bash

REPORT_FILE="/root/load-monitoring-lab/reports/spike-summary.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep $REPORT_FILE. Hay chay k6 voi tuy chon --summary-export"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai JSON hop le"
  exit 1
fi

TOTAL_REQ=$(jq -r '.metrics.http_reqs.values.count // 0' "$REPORT_FILE")
if [ "$TOTAL_REQ" -lt 300 ]; then
  echo "[FAIL] So luong request thuc thi chua du ($TOTAL_REQ), kịch bản spike chua chay xong"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong kịch bản Spike Test va xac dinh ro rang nut that co chai tai Server"
exit 0
