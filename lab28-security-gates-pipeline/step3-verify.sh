#!/bin/bash

GATE3_SCRIPT="/root/security-gate-lab/gate3-image-scan.sh"

# Kiểm tra file script gate3 tồn tại
if [ ! -f "$GATE3_SCRIPT" ]; then
  echo "Chua tim thay tep '$GATE3_SCRIPT'. Hay tao tep theo huong dan!"
  exit 1
fi

# Kiểm tra quyền thực thi
if [ ! -x "$GATE3_SCRIPT" ]; then
  echo "Tep '$GATE3_SCRIPT' chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# Kiểm tra image devsecops-demo:v1.0 tồn tại
if ! docker image inspect devsecops-demo:v1.0 > /dev/null 2>&1; then
  echo "Chua tim thay Docker image 'devsecops-demo:v1.0'. Hay chay script ./gate3-image-scan.sh!"
  exit 1
fi

echo "Chuc mung! Ban da thiet lap thanh cong Gate 3 Container Image Security Scan."
exit 0
