#!/bin/bash

REPORT_FILE="/root/load-monitoring-lab/reports/step2-baseline-state.json"

if [ ! -f "$REPORT_FILE" ]; then
  echo "[FAIL] Khong tim thay tep $REPORT_FILE"
  exit 1
fi

if ! jq empty "$REPORT_FILE" >/dev/null 2>&1; then
  echo "[FAIL] Tep $REPORT_FILE khong hop le"
  exit 1
fi

# Kiem tra Prometheus da ghi nhan du lieu thuc thi
TOTAL_REQ=$(curl -s 'http://localhost:9090/api/v1/query?query=sum(http_requests_total)' | jq -r '.data.result[0].value[1] // 0')
if [ $(echo "$TOTAL_REQ > 200" | bc -l 2>/dev/null || echo 1) -eq 0 ]; then
  echo "[FAIL] Prometheus chua ghi nhan du luong request chay tu k6"
  exit 1
fi

echo "[OK] Da thuc thi thanh cong tai nen va quan sat du lieu giam sat tren Grafana"
exit 0
