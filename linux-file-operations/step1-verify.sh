#!/bin/bash

BASE_DIR="/root/ecommerce-app"

if [ ! -d "$BASE_DIR" ]; then
    echo "[ERROR] Thư mục gốc $BASE_DIR chưa tồn tại. Hãy dùng lệnh 'mkdir -p $BASE_DIR' để bắt đầu."
    exit 1
fi

REQUIRED_DIRS=(
    "$BASE_DIR/configs"
    "$BASE_DIR/logs"
    "$BASE_DIR/src/api"
    "$BASE_DIR/src/models"
    "$BASE_DIR/tests"
)

for d in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$d" ]; then
        echo "[ERROR] Thiếu thư mục bắt buộc: $d. Hãy kiểm tra lại bằng lệnh 'tree $BASE_DIR'."
        exit 1
    fi
done

USER_JS="$BASE_DIR/src/models/user.js"
if [ ! -f "$USER_JS" ]; then
    echo "[ERROR] Chưa tìm thấy file $USER_JS. Hãy dùng lệnh touch để tạo file này."
    exit 1
fi

SERVER_JS="$BASE_DIR/src/api/server.js"
if [ ! -f "$SERVER_JS" ]; then
    echo "[ERROR] Chưa tìm thấy file $SERVER_JS."
    exit 1
fi

if ! grep -q "console.log" "$SERVER_JS"; then
    echo "[ERROR] File $SERVER_JS chưa có nội dung 'console.log(\"Server starting...\");'."
    exit 1
fi

APP_CONF="$BASE_DIR/configs/app.conf"
if [ ! -f "$APP_CONF" ]; then
    echo "[ERROR] Chưa tìm thấy file $APP_CONF."
    exit 1
fi

if ! grep -q "PORT=3000" "$APP_CONF"; then
    echo "[ERROR] File $APP_CONF chưa có dòng nội dung 'PORT=3000'."
    exit 1
fi

echo "[SUCCESS] Xuất sắc! Bạn đã khởi tạo cây thư mục ecommerce-app hoàn chỉnh với đầy đủ các file cấu hình và mã nguồn ban đầu."
exit 0
