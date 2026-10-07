#!/bin/bash
set -e

cd /root/dast-target-app

# 1. Kiem tra tep remediation-plan.txt
if [ ! -f remediation-plan.txt ]; then
  echo "Loi: Tep remediation-plan.txt chua duoc tao!"
  exit 1
fi

COUNT=$(wc -l < remediation-plan.txt)
if [ "$COUNT" -lt 2 ]; then
  echo "Loi: remediation-plan.txt chua chua day du danh sach lo hong DAST can khac phuc!"
  exit 1
fi

echo "Ke hoach khac phuc lo hong DAST da duoc phan tich va tong hop thanh cong!"
exit 0
