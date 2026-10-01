#!/bin/bash

BASE_DIR="/opt/web-service"

if [ ! -d "$BASE_DIR" ]; then
    echo "[ERROR] Thư mục $BASE_DIR không tồn tại."
    exit 1
fi

CHECK_OBJECT() {
    local PATH_NAME="$1"
    local EXP_USER="$2"
    local EXP_GRP="$3"
    local EXP_PERM="$4"
    local DESC="$5"

    if [ ! -e "$PATH_NAME" ]; then
        echo "[ERROR] $DESC ($PATH_NAME) không tồn tại."
        return 1
    fi

    local ACT_USER ACT_GRP ACT_PERM
    ACT_USER=$(stat -c "%U" "$PATH_NAME")
    ACT_GRP=$(stat -c "%G" "$PATH_NAME")
    ACT_PERM=$(stat -c "%a" "$PATH_NAME")

    if [ "$ACT_USER" != "$EXP_USER" ]; then
        echo "[ERROR] $DESC có User sở hữu là '$ACT_USER', mong đợi '$EXP_USER'. Hãy kiểm tra lệnh chown."
        return 1
    fi

    if [ "$ACT_GRP" != "$EXP_GRP" ]; then
        echo "[ERROR] $DESC có Group sở hữu là '$ACT_GRP', mong đợi '$EXP_GRP'. Hãy kiểm tra lệnh chown hoặc chgrp."
        return 1
    fi

    if [ "$ACT_PERM" != "$EXP_PERM" ]; then
        echo "[ERROR] $DESC có quyền là '$ACT_PERM', mong đợi '$EXP_PERM'. Hãy chạy: chmod $EXP_PERM $PATH_NAME"
        return 1
    fi

    return 0
}

CHECK_OBJECT "$BASE_DIR" "webapps" "developers" "755" "Thư mục gốc web-service" || exit 1
CHECK_OBJECT "$BASE_DIR/index.html" "webapps" "developers" "644" "Tệp web tĩnh index.html" || exit 1
CHECK_OBJECT "$BASE_DIR/logs" "webapps" "developers" "775" "Thư mục logs dịch vụ" || exit 1

echo "[SUCCESS] Hoàn hảo! Toàn bộ kiến trúc quyền sở hữu User (webapps), Group (developers) và các cấp độ phân quyền (755, 644, 775) đã được thiết lập chính xác chuẩn bảo mật Production."
exit 0
