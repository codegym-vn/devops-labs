#!/bin/bash

REPORT_FILE="/root/app-opt-lab/reports/before-summary.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep $REPORT_FILE. Hay chay k6 voi tuy chon --summary-export"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai la JSON hop le"
  exit 1
fi

TOTAL_REQ=$(jq -r '.metrics.http_reqs.values.count // 0' "$REPORT_FILE")
if [ "$TOTAL_REQ" -le 0 ]; then
  echo "[FAIL] So luong request trong bao cao bang 0"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong Benchmark Before va ghi nhan duong co so hieu nang ($TOTAL_REQ requests)"
exit 0
