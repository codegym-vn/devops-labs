#!/bin/bash

# Kiểm tra file app.js và run-app.sh tồn tại
if [ ! -f "/root/vault-lab/app.js" ] || [ ! -f "/root/vault-lab/run-app.sh" ]; then
  echo "Chua tim thay tep 'app.js' hoac 'run-app.sh'!"
  exit 1
fi

# Gửi yêu cầu curl kiểm tra endpoint db-status
RESPONSE=$(curl -s http://127.0.0.1:3000/db-status 2>/dev/null || echo "")

if [ -z "$RESPONSE" ]; then
  echo "Ung dung chua khoi chay tren cong 3000. Hay chay: ./run-app.sh"
  exit 1
fi

# Kiểm tra trường connected và user trong response
if ! echo "$RESPONSE" | grep -q '"connected": true'; then
  echo "Ung dung chua nhan duoc DB_PASSWORD tu bien moi truong (connected khong phai true)!"
  exit 1
fi

if ! echo "$RESPONSE" | grep -q '"user": "payment_user"'; then
  echo "Ung dung chua nhan dung DB_USER la 'payment_user'!"
  exit 1
fi

echo "Chuc mung! Ung dung da duoc inject secret an toan tu HashiCorp Vault va hoat dong hoan hao."
exit 0
