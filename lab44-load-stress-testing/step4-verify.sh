#!/bin/bash

SCRIPT_FILE="/root/load-test-lab/scripts/quality-gate.js"
SUMMARY_FILE="/root/load-test-lab/reports/quality-gate-summary.json"
REPORT_FILE="/root/load-test-lab/reports/performance-test-report.json"

if [ ! -f "$SCRIPT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep $SCRIPT_FILE"
  exit 1
fi

if ! grep -q "thresholds:" "$SCRIPT_FILE"; then
  echo "[FAIL] Kich ban quality-gate.js chua khai bao cau hinh thresholds"
  exit 1
fi

if [ ! -f "$SUMMARY_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao $SUMMARY_FILE. Hay chay k6 voi tuy chon --summary-export"
  exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao tong hop $REPORT_FILE"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai la JSON hop le"
  exit 1
fi

echo "[OK] Da thiet lap thanh cong Quality Gate Thresholds va xuat bao cao nghiem thu hieu nang"
exit 0
