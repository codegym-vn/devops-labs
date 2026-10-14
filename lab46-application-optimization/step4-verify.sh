#!/bin/bash

AFTER_FILE="/root/app-opt-lab/reports/after-summary.json"
COMPARISON_FILE="/root/app-opt-lab/reports/optimization-comparison.json"

if [ ! -f "$AFTER_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao $AFTER_FILE"
  exit 1
fi

if ! jq empty "$AFTER_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $AFTER_FILE khong hop le"
  exit 1
fi

TOTAL_REQ=$(jq -r '.metrics.http_reqs.values.count // 0' "$AFTER_FILE")
if [ "$TOTAL_REQ" -le 0 ]; then
  echo "[FAIL] So luong request trong bao cao bang 0"
  exit 1
fi

if [ ! -f "$COMPARISON_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao so sanh $COMPARISON_FILE"
  exit 1
fi

if ! jq -e '.benchmark_comparison.after_optimization' "$COMPARISON_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep so sanh chua co du lieu phan tich after_optimization hop le"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong Benchmark After va hoan tat bao cao so sanh hieu nang"
exit 0
