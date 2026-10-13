#!/bin/bash

# Kiem tra container prometheus dang chay
if [ -z "$(docker ps -q -f name=prometheus)" ]; then
  echo "Container prometheus chua duoc khoi chay."
  exit 1
fi

# Kiem tra Target node-exporter co health la up
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null)
if ! echo "$TARGETS" | grep -q '"health":"up"'; then
  echo "Prometheus chua ket noi thanh cong voi target node-exporter."
  exit 1
fi

# Kiem tra file ket qua truy van infra-promql.json
if [ ! -f /root/infra-monitoring-lab/infra-promql.json ]; then
  echo "Chua tim thay tep /root/infra-monitoring-lab/infra-promql.json."
  exit 1
fi

if ! grep -q '"status":"success"' /root/infra-monitoring-lab/infra-promql.json; then
  echo "Tep infra-promql.json khong chua ket qua thanh cong tu Prometheus API."
  exit 1
fi

echo "Buoc 2 da hoan thanh xuat sac!"
exit 0
