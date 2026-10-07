#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 27: HashiCorp Vault Secret Mgmt    "
echo "================================================================"
echo "Dang khoi dong HashiCorp Vault Server..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo ""
echo "[OK] Vault Server dang hoat dong tai http://127.0.0.1:8200"
echo "[OK] Bien VAULT_ADDR va VAULT_TOKEN da duoc thiet lap san."
echo "Thu muc thuc hanh: /root/vault-lab"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/vault-lab
