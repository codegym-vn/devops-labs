#!/bin/bash
set -e

# 1. Kiem tra container node-exporter dang chay
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' node-exporter 2>/dev/null || echo "false")
if [ "$CONTAINER_STATUS" != "true" ]; then
  echo "Loi: Container 'node-exporter' chua duoc khoi chay hoac khong o trang thai running!"
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
  echo "Loi: Chua tim thay file $RESULT_FILE!"
  exit 1
fi

if ! grep -q "node_cpu_seconds_total" "$RESULT_FILE" || ! grep -q "node_memory_MemAvailable_bytes" "$RESULT_FILE"; then
  echo "Loi: File $RESULT_FILE chua chua day du ca 2 loai metrics counter va gauge theo yeu cau!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Node Exporter da hoat dong tren port 9100 va cung cap dinh dang OpenMetrics hop le!"
exit 0
