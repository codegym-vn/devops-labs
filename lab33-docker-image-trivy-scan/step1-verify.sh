#!/bin/bash

if ! command -v trivy > /dev/null 2>&1; then
  echo "Chua cai dat cong cu Trivy tren he thong."
  exit 1
fi

if ! docker images -q payment-service:v1 | grep -q .; then
  echo "Chua build thanh cong image payment-service:v1."
  exit 1
fi

if [ ! -f /root/container-security-lab/initial-image-report.json ]; then
  echo "Chua xuat bao cao quet ban dau ra initial-image-report.json."
  exit 1
fi

echo "Buoc 1 da hoan thanh thanh cong!"
exit 0
