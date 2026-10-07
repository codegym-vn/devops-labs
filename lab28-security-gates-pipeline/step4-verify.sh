#!/bin/bash

PIPELINE_SCRIPT="/root/security-gate-lab/run-full-pipeline.sh"

# Kiểm tra file run-full-pipeline.sh tồn tại
if [ ! -f "$PIPELINE_SCRIPT" ]; then
  echo "Chua tim thay tep '$PIPELINE_SCRIPT'. Hay tao tep theo huong dan!"
  exit 1
fi

# Kiểm tra quyền thực thi
if [ ! -x "$PIPELINE_SCRIPT" ]; then
  echo "Tep '$PIPELINE_SCRIPT' chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# Kiểm tra file leak tạm đã được xóa sạch
if [ -f "/root/security-gate-lab/aws_leak.env" ]; then
  echo "Tep 'aws_leak.env' van ton tai! Hay xoa bo truoc khi hoan thanh."
  exit 1
fi

# Chạy thử toàn bộ pipeline
cd /root/security-gate-lab
if ! ./run-full-pipeline.sh > /dev/null 2>&1; then
  echo "Quy trinh pipeline that bai! Vui long kiem tra lai ca 3 gates."
  exit 1
fi

echo "Chuc mung! Ban da tich hop va van hanh he thong Security Gates lien hoan xuat sac."
exit 0
