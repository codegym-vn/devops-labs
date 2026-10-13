#!/bin/bash

# Kiem tra file log ung dung ton tai
if [ ! -s /var/log/apps/order-api.log ]; then
  echo "Tep /var/log/apps/order-api.log chua duoc khoi tao hoac bi rong."
  exit 1
fi

# Kiem tra file log Nginx ton tai
if [ ! -s /var/log/apps/nginx-access.log ]; then
  echo "Tep /var/log/apps/nginx-access.log chua duoc khoi tao hoac bi rong."
  exit 1
fi

# Kiem tra file trang thai
if [ ! -f /root/centralized-logging-lab/initial-logs-status.txt ]; then
  echo "Chua tim thay tep /root/centralized-logging-lab/initial-logs-status.txt."
  exit 1
fi

echo "Buoc 1 da hoan thanh xuat sac!"
exit 0
