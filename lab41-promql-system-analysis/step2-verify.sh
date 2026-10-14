#!/bin/bash
set -e

QUERY_FILE="/root/promql-lab/step2-cpu-query.txt"

# 1. Kiem tra file ton tai
if [ ! -f "$QUERY_FILE" ]; then
  echo "Loi: Chua tim thay file $QUERY_FILE!"
  echo "Goi y: Hay ghi cau truy van tinh % CPU vao $QUERY_FILE theo huong dan."
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

# 3. Kiem tra gia tri tra ve phai la mot con so tu 0 den 100
VAL=$(echo "$RESP" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "")
if [ -z "$VAL" ] || [ "$VAL" = "null" ]; then
  echo "Loi: Cau truy van khong tra ve gia tri so nao hop le!"
  exit 1
fi

# So sanh gia tri voi Python hoac awk
IS_VALID=$(awk -v v="$VAL" 'BEGIN { if (v >= 0 && v <= 100) print "yes"; else print "no" }')
if [ "$IS_VALID" != "yes" ]; then
  echo "Loi: Gia tri % CPU tra ve ($VAL) khong nam trong khoang hop le tu 0% den 100%!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Cong thuc PromQL tinh % CPU chinh xac! Gia tri CPU hien tai: $VAL %"
exit 0
