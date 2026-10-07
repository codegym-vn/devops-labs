#!/bin/bash

if [ ! -f /root/container-security-lab/Dockerfile.secure ]; then
  echo "Khong tim thay tep Dockerfile.secure."
  exit 1
fi

if ! grep -q "USER node" /root/container-security-lab/Dockerfile.secure; then
  echo "Dockerfile.secure chua khai bao phan quyen USER node phi dac quyen."
  exit 1
fi

if ! docker images -q payment-service:v2 | grep -q .; then
  echo "Chua build thanh cong image payment-service:v2 tu Dockerfile.secure."
  exit 1
fi

echo "Buoc 3 da hoan thanh thanh cong!"
exit 0
