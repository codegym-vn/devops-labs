#!/bin/bash

SCRIPT_FILE="/root/load-test-lab/scripts/stress-test.js"
REPORT_FILE="/root/load-test-lab/reports/stress-summary.json"

if [ ! -f "$SCRIPT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep $SCRIPT_FILE"
  exit 1
fi

if ! grep -q "stages:" "$SCRIPT_FILE"; then
  echo "[FAIL] Kich ban stress-test.js chua khai bao cau hinh stages da giai doan"
  exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao $REPORT_FILE. Hay chay k6 voi tuy chon --summary-export"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai la JSON hop le"
  exit 1
fi

TOTAL_REQS=$(jq -r '.metrics.http_reqs.values.count // 0' "$REPORT_FILE")
if [ "$TOTAL_REQS" -lt 200 ]; then
  echo "[FAIL] So luong request trong bao cao qua it ($TOTAL_REQS), kịch bản chua chay het cac giai doan"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong Stress Test voi mo hinh Ramping Stages ($TOTAL_REQS requests)"
exit 0
