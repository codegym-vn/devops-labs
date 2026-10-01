#!/bin/bash

TARGET_FILE="/tmp/system_identity.txt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $TARGET_FILE. Hãy tạo file này theo hướng dẫn trước khi bấm Check."
    exit 1
fi

EXPECTED_USER=$(whoami)
EXPECTED_HOST=$(hostname)

USER_LINE=$(grep "^USER:" "$TARGET_FILE" | head -n 1)
HOST_LINE=$(grep "^HOSTNAME:" "$TARGET_FILE" | head -n 1)
DIR_LINE=$(grep "^CURRENT_DIR:" "$TARGET_FILE" | head -n 1)

if [ -z "$USER_LINE" ]; then
    echo "[ERROR] Thiếu dòng 'USER:' trong $TARGET_FILE."
    exit 1
fi

ACTUAL_USER=$(echo "$USER_LINE" | awk '{print $2}')
if [ "$ACTUAL_USER" != "$EXPECTED_USER" ]; then
    echo "[ERROR] USER không chính xác. Mong đợi '$EXPECTED_USER', nhưng nhận được '$ACTUAL_USER'."
    exit 1
fi

if [ -z "$HOST_LINE" ]; then
    echo "[ERROR] Thiếu dòng 'HOSTNAME:' trong $TARGET_FILE."
    exit 1
fi

ACTUAL_HOST=$(echo "$HOST_LINE" | awk '{print $2}')
if [ "$ACTUAL_HOST" != "$EXPECTED_HOST" ]; then
    echo "[ERROR] HOSTNAME không chính xác. Mong đợi '$EXPECTED_HOST', nhưng nhận được '$ACTUAL_HOST'."
    exit 1
fi

if [ -z "$DIR_LINE" ]; then
    echo "[ERROR] Thiếu dòng 'CURRENT_DIR:' trong $TARGET_FILE."
    exit 1
fi

ACTUAL_DIR=$(echo "$DIR_LINE" | awk '{print $2}')
if [[ ! "$ACTUAL_DIR" =~ ^/ ]]; then
    echo "[ERROR] CURRENT_DIR phải là một đường dẫn tuyệt đối hợp lệ (bắt đầu bằng dấu '/'). Giá trị hiện tại: '$ACTUAL_DIR'."
    exit 1
fi

echo "[SUCCESS] Tuyệt vời! File hồ sơ định danh $TARGET_FILE đã ghi nhận chính xác USER ($ACTUAL_USER), HOSTNAME ($ACTUAL_HOST) và CURRENT_DIR ($ACTUAL_DIR)."
exit 0
