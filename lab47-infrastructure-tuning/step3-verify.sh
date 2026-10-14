#!/bin/bash

CONF_FILE="/root/infra-opt-lab/nginx/nginx.conf"

# 1. Kiem tra cau hinh worker_connections
if ! grep -q "worker_connections 4096;" "$CONF_FILE"; then
  echo "[FAIL] worker_connections chua duoc tang len 4096 trong $CONF_FILE"
  exit 1
fi

# 2. Kiem tra keepalive upstream
if ! grep -q "keepalive 64;" "$CONF_FILE"; then
  echo "[FAIL] upstream chua duoc cau hinh keepalive 64 trong $CONF_FILE"
  exit 1
fi

# 3. Kiem tra proxy_http_version 1.1
if ! grep -q "proxy_http_version 1.1;" "$CONF_FILE"; then
  echo "[FAIL] location chua duoc cau hinh proxy_http_version 1.1 trong $CONF_FILE"
  exit 1
fi

# 4. Kiem tra Nginx dang phan hoi
if ! curl -s http://localhost:80/api/data | grep -q '"status": "OK"'; then
  echo "[FAIL] Nginx khong phan hoi sau khi reload"
  exit 1
fi

echo "[OK] Da tinh chinh thanh cong Nginx KeepAlive va cac tham so Kernel"
exit 0
