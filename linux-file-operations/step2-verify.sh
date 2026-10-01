#!/bin/bash

BASE_DIR="/root/ecommerce-app"

if [ ! -d "$BASE_DIR" ]; then
    echo "[ERROR] Thư mục $BASE_DIR không tồn tại."
    exit 1
fi

CONF_BAK="$BASE_DIR/configs/app.conf.backup"
if [ ! -f "$CONF_BAK" ]; then
    echo "[ERROR] Chưa tìm thấy file sao lưu $CONF_BAK. Hãy dùng lệnh 'cp configs/app.conf configs/app.conf.backup'."
    exit 1
fi

BACKUP_DIR="$BASE_DIR/backups/src-snapshot"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "[ERROR] Chưa tìm thấy thư mục sao lưu mã nguồn $BACKUP_DIR. Hãy dùng lệnh 'cp -r src backups/src-snapshot'."
    exit 1
fi

if [ ! -f "$BACKUP_DIR/api/server.js" ] || [ ! -f "$BACKUP_DIR/models/user.js" ]; then
    echo "[ERROR] Thư mục sao lưu $BACKUP_DIR chưa chứa đầy đủ các file mã nguồn từ src."
    exit 1
fi

OLD_LOG="$BASE_DIR/logs/old-service.log"
if [ ! -f "$OLD_LOG" ]; then
    echo "[ERROR] Chưa tìm thấy file $OLD_LOG. Hãy dùng lệnh mv để chuyển app.log.old vào thư mục logs và đổi tên."
    exit 1
fi

TMP_COUNT=$(find "$BASE_DIR" -maxdepth 1 -name "*.tmp" 2>/dev/null | wc -l)
if [ "$TMP_COUNT" -gt 0 ]; then
    echo "[ERROR] Vẫn còn $TMP_COUNT tệp tin '.tmp' tồn tại trong $BASE_DIR. Hãy dùng lệnh 'rm *.tmp' để dọn dẹp."
    exit 1
fi

echo "[SUCCESS] Hoàn hảo! Các thao tác sao lưu (cp), sao chép đệ quy (cp -r), di chuyển đổi tên (mv) và xóa tệp tạm (rm) đã được thực hiện chính xác."
exit 0
