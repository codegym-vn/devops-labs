#!/bin/bash

export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

# Kiểm tra AppRole auth đã được bật
if ! vault auth list | grep -q "approle/"; then
  echo "Chua bat phuong thuc xac thuc 'approle/'. Hay chay: vault auth enable approle"
  exit 1
fi

# Kiểm tra role payment-role tồn tại
if ! vault read auth/approle/role/payment-role > /dev/null 2>&1; then
  echo "Chua tim thay role 'payment-role'. Hay khoi tao role theo huong dan!"
  exit 1
fi

# Kiểm tra hai file role_id.txt và secret_id.txt tồn tại và có nội dung
if [ ! -s "/root/vault-lab/role_id.txt" ] || [ ! -s "/root/vault-lab/secret_id.txt" ]; then
  echo "Chua tim thay tep 'role_id.txt' hoac 'secret_id.txt' (hoac tep bi rong)!"
  exit 1
fi

# Kiểm tra khả năng đăng nhập thực tế với cặp role_id và secret_id
ROLE_ID=$(cat /root/vault-lab/role_id.txt)
SECRET_ID=$(cat /root/vault-lab/secret_id.txt)

LOGIN_TOKEN=$(vault write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID" 2>/dev/null)
if [ -z "$LOGIN_TOKEN" ]; then
  echo "Dang nhap bang AppRole that bai voi RoleID va SecretID hien tai!"
  exit 1
fi

echo "Chuc mung! Ban da cau hinh thanh cong co che xac thuc AppRole cho he thong tu dong."
exit 0
