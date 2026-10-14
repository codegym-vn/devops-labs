#!/bin/bash

AFTER_FILE="/root/infra-opt-lab/reports/after-summary.json"
REPORT_FILE="/root/infra-opt-lab/reports/infra-tuning-report.json"

if [ ! -f "$AFTER_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao $AFTER_FILE"
  exit 1
fi

if ! jq empty "$AFTER_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $AFTER_FILE khong phai JSON hop le"
  exit 1
fi

TOTAL_REQ=$(jq -r '.metrics.http_reqs.values.count // 0' "$AFTER_FILE")
if [ "$TOTAL_REQ" -le 0 ]; then
  echo "[FAIL] So luong request trong bao cao bang 0"
  exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao tong ket $REPORT_FILE"
  exit 1
fi

if ! jq -e '.results_comparison.connection_drops_after' "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Bao cao tong ket chua phan tich ket qua connection_drops_after"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong Benchmark After va hoan tat nghiem thu toi uu ha tang"
exit 0
