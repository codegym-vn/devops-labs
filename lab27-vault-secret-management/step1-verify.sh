#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

# Kiểm tra secret/payment/database tồn tại
if ! vault kv get secret/payment/database > /dev/null 2>&1; then
  echo "Chua tim thay secret tai duong dan 'secret/payment/database'. Vui long thuc hien lenh vault kv put!"
  exit 1
fi

# Kiểm tra trường username và host trong secret
SECRET_USER=$(vault kv get -field=username secret/payment/database 2>/dev/null)
if [ "$SECRET_USER" != "payment_user" ]; then
  echo "Gia tri username khong chinh xac (Hien tai: '$SECRET_USER')."
  exit 1
fi

echo "Chuc mung! Ban da khoi tao KV-v2 Secret Engine va luu tru secret thanh cong."
exit 0
