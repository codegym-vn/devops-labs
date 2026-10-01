#!/bin/bash

ENV_FILE="/tmp/found-env-files.txt"
LEAK_FILE="/tmp/leak-keys.txt"

if [ ! -f "$ENV_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $ENV_FILE. Hãy dùng lệnh 'find' để tìm tất cả các file .env."
    exit 1
fi

ENV_COUNT=$(wc -l < "$ENV_FILE" | tr -d '[:space:]')
if [ "$ENV_COUNT" -ne 2 ]; then
    echo "[ERROR] Số lượng file .env tìm được trong $ENV_FILE là '$ENV_COUNT', mong đợi đúng 2 file."
    exit 1
fi

if ! grep -q "auth-service/configs/auth.env" "$ENV_FILE" || ! grep -q "payment-service/settings/payment.env" "$ENV_FILE"; then
    echo "[ERROR] Danh sách trong $ENV_FILE chưa chứa đúng 2 đường dẫn của auth.env và payment.env."
    exit 1
fi

if [ ! -f "$LEAK_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $LEAK_FILE. Hãy dùng lệnh 'grep -rn' để truy vết từ khóa SECRET_KEY."
    exit 1
fi

LEAK_COUNT=$(wc -l < "$LEAK_FILE" | tr -d '[:space:]')
if [ "$LEAK_COUNT" -ne 2 ]; then
    echo "[ERROR] Số dòng phát hiện rò rỉ trong $LEAK_FILE là '$LEAK_COUNT', mong đợi đúng 2 dòng."
    exit 1
fi

if ! grep -q "super-secret-auth-key-999" "$LEAK_FILE" || ! grep -q "payment-live-vault-888" "$LEAK_FILE"; then
    echo "[ERROR] Nội dung $LEAK_FILE chưa chứa đầy đủ cả 2 khóa bảo mật bị lộ."
    exit 1
fi

echo "[SUCCESS] Hoàn hảo! Bạn đã vận dụng xuất sắc lệnh 'find' để quét tệp theo định dạng và lệnh 'grep -rn' để truy vết đệ quy chuỗi bí mật."
exit 0
