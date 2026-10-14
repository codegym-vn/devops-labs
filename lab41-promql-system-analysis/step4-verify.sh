#!/bin/bash
set -e

FINAL_FILE="/root/promql-lab/final-queries.txt"

# 1. Kiem tra file ton tai
if [ ! -f "$FINAL_FILE" ]; then
  echo "Loi: Chua tim thay file $FINAL_FILE!"
  echo "Goi y: Hay luu bo 5 cau truy van vao $FINAL_FILE theo huong dan."
  exit 1
fi

# 2. Doc va kiem thu tung cau truy van
declare -a KEYS=("CPU_USAGE" "RAM_USAGE" "APP_RPS" "APP_ERROR_RATE" "APP_P95_LATENCY")

for KEY in "${KEYS[@]}"; do
  RAW_QUERY=$(grep "^${KEY}=" "$FINAL_FILE" | cut -d'=' -f2- | tr -d '\r\n')

  if [ -z "$RAW_QUERY" ]; then
    echo "Loi: Khong tim thay dong dinh nghia cho '$KEY' trong $FINAL_FILE!"
    exit 1
  fi

  RESP=$(curl -s -G "http://localhost:9090/api/v1/query" --data-urlencode "query=$RAW_QUERY" || echo "{}")
  STATUS=$(echo "$RESP" | jq -r '.status' 2>/dev/null || echo "")

  if [ "$STATUS" != "success" ]; then
    ERR_MSG=$(echo "$RESP" | jq -r '.error' 2>/dev/null || echo "Unknown error")
    echo "Loi: Cau truy van cho '$KEY' gap loi cu phap: $ERR_MSG"
    exit 1
  fi

  VAL=$(echo "$RESP" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "")
  echo "  [OK] $KEY -> Ket qua: $VAL"
done

echo "[XAC THUC HOAN TAT] Toan bo 5 cau truy van PromQL co ban den nang cao deu thuc thi thanh cong tren Prometheus TSDB!"
exit 0
