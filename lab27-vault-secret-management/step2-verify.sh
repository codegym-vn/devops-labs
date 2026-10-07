#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

# Kiểm tra policy payment-policy tồn tại
if ! vault policy list | grep -q "^payment-policy$"; then
  echo "Chua tim thay policy 'payment-policy'. Hay tao bang lenh: vault policy write payment-policy payment-policy.hcl"
  exit 1
fi

# Kiểm tra nội dung policy có cấu hình đúng path và capabilities
POLICY_CONTENT=$(vault policy read payment-policy 2>/dev/null)
if ! echo "$POLICY_CONTENT" | grep -q "secret/data/payment/\*"; then
  echo "Policy chua khai bao dung duong dan 'secret/data/payment/*'. Vui long kiem tra lai!"
  exit 1
fi

if ! echo "$POLICY_CONTENT" | grep -q "read"; then
  echo "Policy chua khai bao capability 'read'!"
  exit 1
fi

echo "Chuc mung! Ban da thiet lap Vault Policy phan quyen Least Privilege chinh xac."
exit 0
