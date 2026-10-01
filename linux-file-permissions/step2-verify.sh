#!/bin/bash

DIR="/opt/secure-service"

if [ ! -d "$DIR" ]; then
    echo "[ERROR] Thư mục $DIR không tồn tại."
    exit 1
fi

CHECK_PERM() {
    local FILE="$1"
    local EXPECTED="$2"
    local DESC="$3"
    
    if [ ! -f "$FILE" ]; then
        echo "[ERROR] File $FILE không tồn tại."
        return 1
    fi
    
    local ACTUAL
    ACTUAL=$(stat -c "%a" "$FILE")
    
    if [ "$ACTUAL" != "$EXPECTED" ]; then
        echo "[ERROR] $DESC ($FILE) có quyền hiện tại là '$ACTUAL', mong đợi '$EXPECTED'. Hãy chạy lại: chmod $EXPECTED $FILE"
        return 1
    fi
    return 0
}

CHECK_PERM "$DIR/deploy.sh" "755" "Script triển khai" || exit 1
CHECK_PERM "$DIR/config.env" "644" "File cấu hình môi trường" || exit 1
CHECK_PERM "$DIR/service.key" "600" "Khóa bí mật nhạy cảm" || exit 1

echo "[SUCCESS] Xuất sắc! Bộ ba tệp tin nhạy cảm đã được gia cố bảo mật chuẩn xác theo đúng thông số quyền hạn Production (deploy.sh: 755, config.env: 644, service.key: 600)."
exit 0
