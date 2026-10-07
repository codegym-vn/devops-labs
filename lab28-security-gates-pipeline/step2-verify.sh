#!/bin/bash

GATE2_SCRIPT="/root/security-gate-lab/gate2-sca-scan.sh"

# Kiểm tra file script gate2 tồn tại
if [ ! -f "$GATE2_SCRIPT" ]; then
  echo "Chua tim thay tep '$GATE2_SCRIPT'. Hay tao tep theo huong dan!"
  exit 1
fi

# Kiểm tra quyền thực thi
if [ ! -x "$GATE2_SCRIPT" ]; then
  echo "Tep '$GATE2_SCRIPT' chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# Chạy thử script gate2
cd /root/security-gate-lab
if ! ./gate2-sca-scan.sh > /dev/null 2>&1; then
  echo "Script gate2-sca-scan.sh thuc thi that bai tren dependencies hien tai!"
  exit 1
fi

echo "Chuc mung! Ban da thiet lap thanh cong Gate 2 SCA Dependency Scanning."
exit 0
