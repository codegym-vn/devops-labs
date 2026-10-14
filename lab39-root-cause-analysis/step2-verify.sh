#!/bin/bash
set -e

TRACE_REPORT="/root/incident-report/step2-trace.txt"

# 1. Kiem tra file bao cao trace co ton tai khong
if [ ! -f "$TRACE_REPORT" ]; then
  echo "Loi: Chua tim thay file bao cao phan tich trace tai $TRACE_REPORT!"
  echo "Goi y: Hay su dung Jaeger de tim dich vu va span gay nghen, sau do ghi vao $TRACE_REPORT."
  exit 1
fi

# 2. Kiem tra dich vu thu pham
if ! grep -q "CULPRIT_SERVICE=payment-service" "$TRACE_REPORT"; then
  echo "Loi: Dich vu CULPRIT_SERVICE khong chinh xac! Hay xem ky Waterfall trace de biet service nao thuc su bi treo."
  exit 1
fi

# 3. Kiem tra span nut that co chai
if ! grep -q "BOTTLENECK_SPAN=db_acquire_connection" "$TRACE_REPORT"; then
  echo "Loi: Span BOTTLENECK_SPAN chua chinh xac! Span nao trong payment-service ton toi hon 2000ms va bi loi?"
  exit 1
fi

# 4. Kiem tra Trace ID co hop le (32 ky tu hex)
TRACE_ID=$(grep "SAMPLE_TRACE_ID=" "$TRACE_REPORT" | cut -d'=' -f2 | tr -d ' \r\n')
if [[ ! "$TRACE_ID" =~ ^[0-9a-fA-F]{32}$ ]]; then
  echo "Loi: SAMPLE_TRACE_ID ('$TRACE_ID') khong hop le! Trace ID phai la mot chuoi 32 ky tu hexa."
  exit 1
fi

echo "[XAC THUC THANH CONG] Phan tich Distributed Tracing hoan hao: Thu pham la 'payment-service' tai span 'db_acquire_connection' voi Trace ID: $TRACE_ID"
exit 0
