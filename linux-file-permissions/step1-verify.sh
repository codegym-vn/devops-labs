#!/bin/bash

TARGET_FILE="/tmp/perm-analysis.txt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file báo cáo $TARGET_FILE. Hãy hoàn thành thử thách trước khi bấm Check."
    exit 1
fi

CHECK_LINE() {
    local KEY="$1"
    local EXPECTED="$2"
    local ACTUAL
    ACTUAL=$(grep "^${KEY}:" "$TARGET_FILE" | head -n 1 | awk '{print $2}')
    if [ "$ACTUAL" != "$EXPECTED" ]; then
        echo "[ERROR] ${KEY} không chính xác. Mong đợi '$EXPECTED', nhưng nhận được '$ACTUAL'."
        return 1
    fi
    return 0
}

CHECK_LINE "FILE_TYPE" "regular" || exit 1
CHECK_LINE "USER_PERM" "rw-" || exit 1
CHECK_LINE "GROUP_PERM" "r--" || exit 1
CHECK_LINE "OTHERS_PERM" "---" || exit 1

echo "[SUCCESS] Chính xác! Bạn đã giải mã chuẩn xác 10 ký tự quyền hạn của tệp company_secrets.txt (-rw-r-----)."
exit 0
