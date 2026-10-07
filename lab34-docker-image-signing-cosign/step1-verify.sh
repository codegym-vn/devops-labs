#!/bin/bash

if ! command -v cosign > /dev/null 2>&1; then
  echo "Chua cai dat cong cu Cosign."
  exit 1
fi

if ! curl -s http://localhost:5000/v2/ > /dev/null 2>&1; then
  echo "Registry chua khoi chay tren cong 5000."
  exit 1
fi

if [ ! -f /root/cosign-signing-lab/cosign.key ] || [ ! -f /root/cosign-signing-lab/cosign.pub ]; then
  echo "Chua sinh cap khoa cosign.key va cosign.pub."
  exit 1
fi

echo "Buoc 1 da hoan thanh thanh cong!"
exit 0
