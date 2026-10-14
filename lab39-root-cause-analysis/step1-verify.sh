#!/bin/bash
set -e

REPORT_FILE="/root/incident-report/step1-triage.txt"

# 1. Kiem tra file bao cao triage co ton tai khong
if [ ! -f "$REPORT_FILE" ]; then
  echo "Loi: Chua tim thay file bao cao khao sat tai $REPORT_FILE!"
  echo "Goi y: Hay thuc hien triage hien truong va luu ket qua vao /root/incident-report/step1-triage.txt theo huong dan."
  exit 1
fi

# 2. Kiem tra ma trang thai quan sat duoc (Phai la ma loi 50x)
if ! grep -qE "OBSERVED_STATUS_CODE=(504|500|502|503)" "$REPORT_FILE"; then
  echo "Loi: Ma trang thai OBSERVED_STATUS_CODE trong bao cao khong chinh xac hoac chua phan anh dung ma loi 50x!"
  exit 1
fi

# 3. Kiem tra trieu chung chinh (Chua tu khoa TIMEOUT hoac LATENCY)
if ! grep -qiE "TIMEOUT|LATENCY" "$REPORT_FILE"; then
  echo "Loi: Truong PRIMARY_SYMPTOM chua ghi nhan dung trieu chung tre hoac timeout!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Giai doan Triage hoan tat: Xac nhan su co P1 voi ma loi 504 Gateway Timeout do do tre cao."
exit 0
