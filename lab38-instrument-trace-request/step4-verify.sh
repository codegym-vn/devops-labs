#!/bin/bash
set -e

# 1. Kiem tra tep error-trace.json ton tai
if [ ! -f /root/tracing-lab/error-trace.json ]; then
  echo "Loi: Khong tim thay tep /root/tracing-lab/error-trace.json!"
  echo "Goi y: Hay chay lenh curl trich xuat trace loi o buoc 4.4."
  exit 1
fi

# 2. Kiem tra noi dung tep chua du lieu Trace JSON hop le
TRACE_ID=$(cat /root/tracing-lab/error-trace.json | jq -r '.data[0].traceID' 2>/dev/null || echo "")
if [ -z "$TRACE_ID" ] || [ "$TRACE_ID" = "null" ]; then
  echo "Loi: Tep error-trace.json khong chua du lieu Trace hop le hoac chua co giao dich loi nao duoc ghi nhan!"
  echo "Goi y: Hay gui don hang voi totalAmount > 5000 de kich hoat loi phan tan truoc khi trich xuat."
  exit 1
fi

# 3. Kiem tra xem trace co chua span co tag error = true hay khong
HAS_ERROR_TAG=$(cat /root/tracing-lab/error-trace.json | jq -r '[.data[0].spans[].tags[] | select(.key == "error" and .value == true)] | length' 2>/dev/null || echo "0")
if [ "$HAS_ERROR_TAG" -lt 1 ]; then
  echo "Loi: Trace trong error-trace.json khong co nhan danh dau loi (error=true)!"
  exit 1
fi

echo "Xac thuc thanh cong: Da phat hien Trace loi phan tan $TRACE_ID voi the error=true!"
exit 0
