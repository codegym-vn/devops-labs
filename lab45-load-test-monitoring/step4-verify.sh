#!/bin/bash

REPORT_FILE="/root/load-monitoring-lab/reports/capacity-planning-report.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep bao cao $REPORT_FILE"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong phai la JSON hop le"
  exit 1
fi

if ! jq -e '.capacity_boundaries.breaking_point_vus' "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Bao cao chua phan tich nguong breaking point cua he thong"
  exit 1
fi

echo "[OK] Da hoan thanh xuat sac bao cao Capacity Planning & Correlation Analysis"
exit 0
