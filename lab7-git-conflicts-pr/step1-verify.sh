#!/bin/bash

BARE_REPO="/srv/git/central-repo.git"

# 1. Kiem tra nhanh feature/auth da duoc push len central repo chua
if ! git --git-dir="$BARE_REPO" branch --list | grep -qw "feature/auth"; then
    echo "[ERROR] Nhanh 'feature/auth' chua xuat hien tren remote server. Hay dung lenh: git push -u origin feature/auth"
    exit 1
fi

# 2. Kiem tra ham verify_token trong app.py tren nhanh feature/auth
if ! git --git-dir="$BARE_REPO" show feature/auth:app.py 2>/dev/null | grep -q "verify_token"; then
    echo "[ERROR] File app.py tren nhanh feature/auth chua co ham verify_token. Hay kiem tra lai ma nguon da commit."
    exit 1
fi

echo "[SUCCESS] Nhanh feature/auth da duoc tao va push len Central Server thanh cong voi ham verify_token hop le!"
exit 0
