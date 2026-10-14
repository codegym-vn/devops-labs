#!/bin/bash

# 1. Kiem tra Target API hoat dong
if ! curl -s http://localhost:8080/health | grep -q "UP"; then
  echo "[FAIL] Target Catalog API chua khoi dong tai port 8080"
  exit 1
fi

# 2. Kiem tra tep bao cao initial-report.json
REPORT_FILE="/root/app-opt-lab/reports/initial-report.json"
if [ ! -f "$REPORT_FILE" ] || ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Khong tim thay tep bao cao $REPORT_FILE hoac dinh dang khong hop le"
  exit 1
fi

# 3. Kiem tra tep app.env
if [ ! -f /root/app-opt-lab/config/app.env ]; then
  echo "[FAIL] Khong tim thay tep cau hinh /root/app-opt-lab/config/app.env"
  exit 1
fi

echo "[OK] Da khao sat thanh cong hien trang he thong va bao cao chan doan"
exit 0
