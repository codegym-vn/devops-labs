#!/bin/bash

TARGET_FILE="/tmp/cert_subject.txt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] Chua tim thay file $TARGET_FILE. Hay luu ten to chuc tu certificate subject vao file nay."
    exit 1
fi

CONTENT=$(cat "$TARGET_FILE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

# Kiem tra co chua "github" trong noi dung (linh hoat voi cac bien the)
if echo "$CONTENT" | grep -qi "github"; then
    echo "[SUCCESS] Chinh xac! Ban da trich xuat thanh cong thong tin to chuc tu certificate cua github.com."
    exit 0
else
    echo "[ERROR] Ket qua '$CONTENT' chua chinh xac. Goi y: Hay dung openssl s_client ket noi toi github.com:443 va tim truong subject, lay ten to chuc (O = ...)."
    exit 1
fi
