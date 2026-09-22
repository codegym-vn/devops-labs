#!/bin/bash

# Kiểm tra phân giải tên miền db.production qua getent hoặc trực tiếp trong /etc/hosts
if getent hosts db.production 2>/dev/null | grep -q "10\.0\.0\.50" || grep -E -q '^\s*10\.0\.0\.50\s+.*db\.production' /etc/hosts 2>/dev/null; then
    echo "[SUCCESS] Ten mien db.production da duoc map thanh cong ve 10.0.0.50 trong /etc/hosts."
    exit 0
else
    echo "[ERROR] Chua tim thay ban ghi phan giai '10.0.0.50 db.production'. Hay kiem tra lai noi dung file /etc/hosts."
    exit 1
fi
