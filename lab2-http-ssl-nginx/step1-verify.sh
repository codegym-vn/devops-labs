#!/bin/bash

TARGET_FILE="/tmp/http_status.txt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] Chua tim thay file $TARGET_FILE. Hay luu HTTP status code vao file nay (vi du: echo \"200\" > /tmp/http_status.txt)."
    exit 1
fi

CONTENT=$(cat "$TARGET_FILE" | tr -d '[:space:]')

if [ "$CONTENT" = "200" ]; then
    echo "[SUCCESS] Chinh xac! HTTP status code 200 OK cho thay server da xu ly request thanh cong va tra ve noi dung."
    exit 0
else
    echo "[ERROR] Ket qua '$CONTENT' chua chinh xac. Goi y: Hay dung curl voi tham so -o /dev/null -s -w de lay status code cua http://example.com."
    exit 1
fi
