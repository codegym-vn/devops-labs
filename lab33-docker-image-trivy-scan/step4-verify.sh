#!/bin/bash

if [ ! -x /root/container-security-lab/container-security-gate.sh ]; then
  echo "Tep container-security-gate.sh chua duoc tao hoac chua co quyen thuc thi."
  exit 1
fi

if ! /root/container-security-lab/container-security-gate.sh payment-service:v2 > /dev/null 2>&1; then
  echo "Security Gate that bai khi quet payment-service:v2."
  exit 1
fi

if [ ! -s /root/container-security-lab/container-sbom.json ]; then
  echo "Chua xuat thanh cong tep container-sbom.json."
  exit 1
fi

echo "Xin chuc mung! Ban da hoan thanh toan bo Lab 33!"
exit 0
