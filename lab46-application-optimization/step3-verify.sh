#!/bin/bash

# 1. Kiem tra cau hinh app.env
if ! grep -q "CACHE_ENABLED=true" /root/app-opt-lab/config/app.env; then
  echo "[FAIL] CACHE_ENABLED chua duoc bat thanh true trong /root/app-opt-lab/config/app.env"
  exit 1
fi

# 2. Kiem tra health check
if ! curl -s http://localhost:8080/health | grep -q '"cache": "ENABLED"'; then
  echo "[FAIL] Ung dung chua nhan dien trang thai cache ENABLED"
  exit 1
fi

# 3. Kiem tra X-Cache-Status
CACHE_HEADER=$(curl -i -s http://localhost:8080/api/catalog | grep -i "X-Cache-Status:" | tr -d '\r\n')
if [ -z "$CACHE_HEADER" ] || echo "$CACHE_HEADER" | grep -q "BYPASS"; then
  echo "[FAIL] API van dang o trang thai BYPASS cache"
  exit 1
fi

echo "[OK] Da kich hoat thanh cong Cache-Aside ($CACHE_HEADER)"
exit 0
