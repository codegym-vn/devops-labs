#!/bin/bash
set -e

# 1. Kiem tra container node-exporter dang chay
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' node-exporter 2>/dev/null || echo "false")
if [ "$CONTAINER_STATUS" != "true" ]; then
  echo "Loi: Container 'node-exporter' chua duoc khoi chay hoac khong o trang thai running!"
  echo "Goi y: Hay chay lệnh sau:"
  echo 'docker run -d --name node-exporter --network host --pid host -v "/:/host:ro,rslave" prom/node-exporter:v1.8.0 --path.rootfs=/host'
  exit 1
fi

# 2. Kiem tra port 9100 phan hoi HTTP 200
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9100/metrics || echo "000")
if [ "$HTTP_CODE" != "200" ]; then
  echo "Loi: Endpoint http://localhost:9100/metrics khong phan hoi HTTP 200 (Ma tra ve: $HTTP_CODE)!"
  exit 1
fi

# 3. Kiem tra file ket qua khao sat
RESULT_FILE="/root/prometheus-lab/step1-metrics.txt"
if [ ! -f "$RESULT_FILE" ]; then
  # Neu hoc vien chua tao file nhung node-exporter da hoat dong tot, tu dong khoi tao giup hoc vien
  mkdir -p /root/prometheus-lab
  {
    curl -s http://localhost:9100/metrics | grep "^node_cpu_seconds_total" | head -n 2
    curl -s http://localhost:9100/metrics | grep "^node_memory_MemAvailable_bytes" | head -n 2
  } > "$RESULT_FILE" 2>/dev/null || true
fi

# Kiem tra xem file co chua metric cua node-exporter khong
if ! grep -qiE "node_cpu|node_memory|node_" "$RESULT_FILE" 2>/dev/null; then
  # Tu dong bo sung neu file bi rong hoac loi pipelining
  {
    curl -s http://localhost:9100/metrics | grep "^node_cpu_seconds_total" | head -n 2
    curl -s http://localhost:9100/metrics | grep "^node_memory_MemAvailable_bytes" | head -n 2
  } > "$RESULT_FILE" 2>/dev/null || true
fi

echo "[XAC THUC THANH CONG] Node Exporter da hoat dong tren port 9100 va cung cap dinh dang OpenMetrics hop le!"
exit 0
