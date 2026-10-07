#!/bin/bash
set -e

# 1. Cai dat Vault binary va Node.js
if ! command -v vault > /dev/null 2>&1 || ! command -v node > /dev/null 2>&1; then
  apt-get update -qq > /dev/null 2>&1
  apt-get install -y -qq curl unzip jq nodejs > /dev/null 2>&1
  curl -fsSL https://releases.hashicorp.com/vault/1.15.6/vault_1.15.6_linux_amd64.zip -o /tmp/vault.zip
  unzip -q /tmp/vault.zip -d /usr/local/bin
  rm -f /tmp/vault.zip
  chmod +x /usr/local/bin/vault
fi

# 2. Khoi chay Vault Server o dev mode
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

nohup vault server -dev -dev-root-token-id="root" -dev-listen-address="0.0.0.0:8200" > /tmp/vault.log 2>&1 &

# Cho Vault san sang
for i in {1..30}; do
  if vault status > /dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Cau hinh bien moi truong cho bashrc
if ! grep -q "VAULT_ADDR" /root/.bashrc; then
  echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /root/.bashrc
  echo "export VAULT_TOKEN='root'" >> /root/.bashrc
fi

# 3. Tao thu muc thuc hanh va ung dung mau
mkdir -p /root/vault-lab
cd /root/vault-lab

touch /tmp/background-finished
