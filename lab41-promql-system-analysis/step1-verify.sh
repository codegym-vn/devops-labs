#!/bin/bash
set -e

QUERY_FILE="/root/promql-lab/step1-query.txt"

# 1. Kiem tra file query ton tai
if [ ! -f "$QUERY_FILE" ]; then
  echo "Loi: Chua tim thay file $QUERY_FILE!"
  echo "Goi y: Hay ghi cau truy van vao /root/promql-lab/step1-query.txt theo huong dan."
  exit 1
fi

QUERY=$(cat "$QUERY_FILE" | tr -d '\r\n')
if [ -z "$QUERY" ]; then
  echo "Loi: File $QUERY_FILE bi rong!"
  exit 1
fi

# 2. Thuc thi query truc tiep qua Prometheus API
RESP=$(curl -s -G "http://localhost:9090/api/v1/query" --data-urlencode "query=$QUERY" || echo "{}")
STATUS=$(echo "$RESP" | jq -r '.status' 2>/dev/null || echo "")

if [ "$STATUS" != "success" ]; then
  ERR_MSG=$(echo "$RESP" | jq -r '.error' 2>/dev/null || echo "Unknown error")
  echo "Loi: Cau truy van PromQL khong hop le hoac gap loi cu phap: $ERR_MSG"
  exit 1
fi

# 3. Kiem tra ket qua tra ve
RESULT_COUNT=$(echo "$RESP" | jq -r '.data.result | length' 2>/dev/null || echo "0")
if [ "$RESULT_COUNT" -eq 0 ]; then
  echo "Loi: Cau truy van hop le nhung khong tra ve du lieu time-series nao phu hop voi /api/orders va loi status!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Cau truy van PromQL chinh xac va tra ve $RESULT_COUNT chuoi thoi gian phu hop!"
exit 0
