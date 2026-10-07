#!/bin/bash

CONFIG_FILE="/root/secret-leak-lab/.gitleaks.toml"

# Kiểm tra file cấu hình .gitleaks.toml tồn tại
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Chua tim thay tep cau hinh '$CONFIG_FILE'!"
  exit 1
fi

# Kiểm tra nội dung allowlist
if ! grep -q "github_sync" "$CONFIG_FILE"; then
  echo "Tep cau hinh chua dinh nghia allowlist cho 'github_sync.js'!"
  exit 1
fi

# Kiểm tra commit mới đã thành công
cd /root/secret-leak-lab
LAST_MSG=$(git log -1 --pretty=%B)
if ! echo "$LAST_MSG" | grep -q "allowlist"; then
  echo "Chua commit thanh cong tep '.gitleaks.toml' va 'github_sync.js'. Vui long commit len Git!"
  exit 1
fi

echo "Chuc mung! Ban da cau hinh thanh cong co che quan tri ngoai le (Allowlist) voi Gitleaks."
exit 0
