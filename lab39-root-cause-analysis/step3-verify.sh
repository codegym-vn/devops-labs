#!/bin/bash
set -e

RCA_REPORT="/root/incident-report/step3-rootcause.txt"

# 1. Kiem tra file bao cao root cause
if [ ! -f "$RCA_REPORT" ]; then
  echo "Loi: Chua tim thay file bao cao nguyen nhan goc re tai $RCA_REPORT!"
  echo "Goi y: Hay tra cuu log error tren Loki/file log, kiem tra cau hinh .env va ghi vao $RCA_REPORT."
  exit 1
fi

# 2. Kiem tra nguyen nhan goc
if ! grep -qiE "CONNECTION_POOL_EXHAUSTED|POOL_EXHAUSTION|POOL_EXHAUSTED" "$RCA_REPORT"; then
  echo "Loi: Truong ROOT_CAUSE chua xac dinh dung nguyen nhan can kiet Connection Pool!"
  exit 1
fi

# 3. Kiem tra bien cau hinh bi loi
if ! grep -q "FAULTY_VARIABLE=DB_POOL_MAX" "$RCA_REPORT"; then
  echo "Loi: Bien cau hinh FAULTY_VARIABLE khong chinh xac! Bien nao trong payment-service.env dang gioi han pool size?"
  exit 1
fi

# 4. Kiem tra gia tri hien tai
if ! grep -q "CURRENT_VALUE=2" "$RCA_REPORT"; then
  echo "Loi: Gia tri CURRENT_VALUE khong chinh xac! Hay kiem tra lai noi dung payment-service.env."
  exit 1
fi

echo "[XAC THUC THANH CONG] Tim ra nguyen nhan goc re: Can kiet Connection Pool do DB_POOL_MAX=2 qua nho so voi tai thuc te."
exit 0
