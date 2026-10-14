#!/bin/bash

REPORT_FILE="/root/load-test-lab/reports/baseline-summary.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Chua tim thay tep bao cao $REPORT_FILE. Hay chay k6 voi tuy chon --summary-export"
  exit 1
fi

# Kiem tra tinh hop le cua tep JSON
if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai la JSON hop le"
  exit 1
fi

# Kiem tra tong so request da gui phai lon hon 0
TOTAL_REQS=$(jq -r '.metrics.http_reqs.values.count // 0' "$REPORT_FILE")
if [ "$TOTAL_REQS" -le 0 ]; then
  echo "[FAIL] So luong request ghi nhan trong bao cao bang 0"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong kiem thu Baseline va xuat day du bao cao Throughput/Latency ($TOTAL_REQS requests)"
exit 0
