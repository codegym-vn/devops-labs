#!/bin/bash
set -e

QUERY_FILE="/root/promql-lab/step3-p95-query.txt"

# 1. Kiem tra file ton tai
if [ ! -f "$QUERY_FILE" ]; then
  echo "Loi: Chua tim thay file $QUERY_FILE!"
  echo "Goi y: Hay ghi cau truy van tinh do tre p95 vao $QUERY_FILE theo huong dan."
  exit 1
fi

QUERY=$(cat "$QUERY_FILE" | tr -d '\r\n')
if [ -z "$QUERY" ]; then
  echo "Loi: File $QUERY_FILE bi rong!"
  exit 1
fi

if ! echo "$QUERY" | grep -q "histogram_quantile" || ! echo "$QUERY" | grep -q "0.95"; then
  echo "Loi: Cau truy van phai su dung ham 'histogram_quantile' voi nguong '0.95'!"
  exit 1
fi

# 2. Thuc thi query truc tiep qua Prometheus API
RESP=$(curl -s -G "http://localhost:9090/api/v1/query" --data-urlencode "query=$QUERY" || echo "{}")
STATUS=$(echo "$RESP" | jq -r '.status' 2>/dev/null || echo "")

if [ "$STATUS" != "success" ]; then
  ERR_MSG=$(echo "$RESP" | jq -r '.error' 2>/dev/null || echo "Unknown error")
  echo "Loi: Cau truy van PromQL khong hop le: $ERR_MSG"
  exit 1
fi

# 3. Kiem tra gia tri p95
VAL=$(echo "$RESP" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "")
if [ -z "$VAL" ] || [ "$VAL" = "null" ] || [ "$VAL" = "NaN" ]; then
  echo "Loi: Ham histogram_quantile khong tra ve ket qua so hop le (Ket qua: $VAL)!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Do tre p95 da duoc tinh toan chinh xac: $VAL giay!"
exit 0
