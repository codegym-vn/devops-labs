#!/bin/bash

if [ ! -f /root/app-monitoring-lab/promql-analysis.json ]; then
  echo "Khong tim thay tep promql-analysis.json."
  exit 1
fi

if ! grep -q '"status":"success"' /root/app-monitoring-lab/promql-analysis.json; then
  echo "Truy van PromQL that bai hoac tệp ket qua khong hop le."
  exit 1
fi

echo "Xin chuc mung! Ban da hoan thanh toan bo Lab 35!"
exit 0
