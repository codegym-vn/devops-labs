#!/bin/bash

GATE1_SCRIPT="/root/security-gate-lab/gate1-secret-scan.sh"

# Kiểm tra file script gate1 tồn tại
if [ ! -f "$GATE1_SCRIPT" ]; then
  echo "Chua tim thay tep '$GATE1_SCRIPT'. Hay tao tep theo huong dan!"
  exit 1
fi

# Kiểm tra quyền thực thi
if [ ! -x "$GATE1_SCRIPT" ]; then
  echo "Tep '$GATE1_SCRIPT' chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# Chạy thử script gate1
cd /root/security-gate-lab
if ! ./gate1-secret-scan.sh > /dev/null 2>&1; then
  echo "Script gate1-secret-scan.sh thuc thi that bai tren ma nguon hien tai!"
  exit 1
fi

echo "Chuc mung! Ban da thiet lap thanh cong Gate 1 Secret Scanning."
exit 0
