#!/bin/bash

# Kiem tra script simulate-incident.sh ton tai
if [ ! -f /root/centralized-logging-lab/simulate-incident.sh ]; then
  echo "Chua tim thay kich ban /root/centralized-logging-lab/simulate-incident.sh."
  exit 1
fi

# Kiem tra tep bao cao centralized-logging-report.json
if [ ! -f /root/centralized-logging-lab/centralized-logging-report.json ]; then
  echo "Chua tim thay tep bao cao /root/centralized-logging-lab/centralized-logging-report.json."
  exit 1
fi

# Kiem tra noi dung ket qua hop le
if ! grep -q '"status":"success"' /root/centralized-logging-lab/centralized-logging-report.json; then
  echo "Truy van LogQL that bai hoac tep ket qua khong hop le."
  exit 1
fi

if ! grep -q 'req_critical_8899' /root/centralized-logging-lab/centralized-logging-report.json; then
  echo "Bao cao chua ghi nhan duoc ma giao dich su co req_critical_8899."
  exit 1
fi

echo "Xin chuc mung! Ban da hoan thanh toan bo Lab 37!"
exit 0
