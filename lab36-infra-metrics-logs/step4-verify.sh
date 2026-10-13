#!/bin/bash

# Kiem tra script simulate-infra-events.sh ton tai
if [ ! -f /root/infra-monitoring-lab/simulate-infra-events.sh ]; then
  echo "Chua tim thay kich ban /root/infra-monitoring-lab/simulate-infra-events.sh."
  exit 1
fi

# Kiem tra tep bao cao infra-observability-summary.json
if [ ! -f /root/infra-monitoring-lab/infra-observability-summary.json ]; then
  echo "Chua tim thay tep bao cao /root/infra-monitoring-lab/infra-observability-summary.json."
  exit 1
fi

# Kiem tra noi dung ket qua truy van LogQL hop le
if ! grep -q '"status":"success"' /root/infra-monitoring-lab/infra-observability-summary.json; then
  echo "Truy van LogQL that bai hoac tep ket qua khong hop le."
  exit 1
fi

if ! grep -q 'CRITICAL' /root/infra-monitoring-lab/infra-observability-summary.json; then
  echo "Ket qua LogQL chua ghi nhan duoc su kien CRITICAL da mo phong."
  exit 1
fi

echo "Xin chuc mung! Ban da hoan thanh toan bo Lab 36!"
exit 0
