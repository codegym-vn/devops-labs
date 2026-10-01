#!/bin/bash

CHECKPOINT_FILE="/tmp/nav_checkpoint.txt"
REACHED_FILE="/tmp/.nav_reached"

if [ ! -f "$CHECKPOINT_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $CHECKPOINT_FILE. Hãy làm theo hướng dẫn các bước điều hướng và lưu kết quả pwd vào file này."
    exit 1
fi

CONTENT=$(cat "$CHECKPOINT_FILE" | tr -d '[:space:]')

if [ "$CONTENT" != "/etc" ]; then
    echo "[ERROR] Giá trị trong $CHECKPOINT_FILE là '$CONTENT', không phải '/etc'. Hãy đảm bảo bạn đã dùng 'cd -' quay lại /etc và ghi lại 'pwd > $CHECKPOINT_FILE'."
    exit 1
fi

if [ ! -f "$REACHED_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $REACHED_FILE. Hãy tạo file này bằng lệnh touch với đường dẫn tương đối từ /etc (ví dụ: touch ../tmp/.nav_reached)."
    exit 1
fi

echo "[SUCCESS] Hoàn hảo! Bạn đã làm chủ hoàn toàn đường dẫn tương đối (..), đường dẫn tuyệt đối (/) và lệnh chuyển đổi nhanh 'cd -'."
exit 0
