#!/bin/bash

# Kiem tra container node-exporter dang chay
if [ -z "$(docker ps -q -f name=node-exporter)" ]; then
  echo "Container node-exporter chua duoc khoi chay."
  exit 1
fi

# Kiem tra endpoint /metrics tra ve du lieu hop le
METRICS=$(curl -s http://localhost:9100/metrics 2>/dev/null)

if ! echo "$METRICS" | grep -q "node_memory_MemTotal_bytes"; then
  echo "Node Exporter chua san sang hoac khong tra ve chi so bo nho node_memory_MemTotal_bytes."
  exit 1
fi

if ! echo "$METRICS" | grep -q "node_cpu_seconds_total"; then
  echo "Node Exporter khong tra ve chi so CPU node_cpu_seconds_total."
  exit 1
fi

if [ ! -f /root/infra-monitoring-lab/node-exporter-status.txt ]; then
  echo "Chua tim thay tep /root/infra-monitoring-lab/node-exporter-status.txt."
  exit 1
fi

echo "Buoc 1 da hoan thanh xuat sac!"
exit 0
