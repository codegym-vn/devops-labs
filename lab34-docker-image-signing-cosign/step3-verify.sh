#!/bin/bash

cd /root/cosign-signing-lab 2>/dev/null || true

if [ ! -f /root/cosign-signing-lab/cosign.pub ]; then
  echo "Khong tim thay khoa cong khai cosign.pub."
  exit 1
fi

if ! cosign verify --key /root/cosign-signing-lab/cosign.pub --allow-insecure-registry localhost:5000/order-service:v1.0 > /dev/null 2>&1; then
  echo "Xac thuc chu ky cho image order-service that bai."
  exit 1
fi

if ! curl -s http://localhost:5000/v2/malicious-service/tags/list 2>/dev/null | grep -q '"v1.0"'; then
  echo "Chua thuc hien day image gia mao malicious-service:v1.0 len Registry de thu nghiem."
  exit 1
fi

echo "Buoc 3 da hoan thanh thanh cong!"
exit 0
