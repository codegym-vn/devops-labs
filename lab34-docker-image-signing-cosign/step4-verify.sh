#!/bin/bash

if ! curl -s http://localhost:5000/v2/order-service/tags/list 2>/dev/null | grep -q '\.sbom'; then
  echo "Chua dinh kem thanh cong SBOM len Registry (chua co tag .sbom)."
  exit 1
fi

if [ ! -x /root/cosign-signing-lab/verify-deployment-gate.sh ]; then
  echo "Khong tim thay script verify-deployment-gate.sh hoac chua cap quyen thuc thi."
  exit 1
fi

if ! /root/cosign-signing-lab/verify-deployment-gate.sh localhost:5000/order-service:v1.0 > /dev/null 2>&1; then
  echo "Deployment Gate khong xac thuc duoc image da ky."
  exit 1
fi

echo "Xin chuc mung! Ban da hoan thanh toan bo Lab 34!"
exit 0
