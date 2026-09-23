#!/bin/bash

# Kiem tra file /root/secret_recovered.txt ton tai
if [ ! -f /root/secret_recovered.txt ]; then
    echo "[ERROR] File /root/secret_recovered.txt chua ton tai. Hay dung git cat-file de doc noi dung blob secret.txt va ghi vao file nay."
    exit 1
fi

CONTENT=$(cat /root/secret_recovered.txt | tr -d '[:space:]')
EXPECTED="API_TOKEN_XYZ_98765_RECOVERED"

if [ "$CONTENT" = "$EXPECTED" ]; then
    echo "[SUCCESS] Giai ma thanh cong! Ban da truy vet chinh xac tu commit -> tree -> blob secret.txt."
    echo "Noi dung token thu duoc: $CONTENT"
    exit 0
else
    echo "[ERROR] Noi dung file /root/secret_recovered.txt chua dung."
    echo "Gia tri mong doi: $EXPECTED"
    echo "Gia tri thuc te: $CONTENT"
    exit 1
fi
