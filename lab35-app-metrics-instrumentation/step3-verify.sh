#!/bin/bash

if ! docker ps | grep -q prometheus; then
  echo "Prometheus container chua khoi chay."
  exit 1
fi

TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null)

if ! echo "$TARGETS" | grep -q '"health":"up"'; then
  echo "Target order-api chua o trang thai UP tren Prometheus."
  exit 1
fi

echo "Buoc 3 da hoan thanh thanh cong!"
exit 0
