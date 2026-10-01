#!/bin/bash

TARGET_FILE="/tmp/log-analysis.txt"
SOURCE_LOG="/var/log/myapp/service.log"

if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file báo cáo $TARGET_FILE. Hãy hoàn thành các bước trích xuất theo hướng dẫn."
    exit 1
fi

LINE_COUNT=$(wc -l < "$TARGET_FILE" | tr -d '[:space:]')
if [ "$LINE_COUNT" -ne 10 ]; then
    echo "[ERROR] File $TARGET_FILE hiện có $LINE_COUNT dòng, mong đợi đúng 10 dòng (5 dòng đầu + 5 dòng cuối)."
    exit 1
fi

EXPECTED_HEAD=$(head -n 5 "$SOURCE_LOG")
ACTUAL_HEAD=$(head -n 5 "$TARGET_FILE")
if [ "$EXPECTED_HEAD" != "$ACTUAL_HEAD" ]; then
    echo "[ERROR] 5 dòng đầu tiên trong $TARGET_FILE không khớp với kết quả của 'head -n 5 $SOURCE_LOG'."
    exit 1
fi

EXPECTED_TAIL=$(tail -n 5 "$SOURCE_LOG")
ACTUAL_TAIL=$(tail -n 5 "$TARGET_FILE")
if [ "$EXPECTED_TAIL" != "$ACTUAL_TAIL" ]; then
    echo "[ERROR] 5 dòng cuối cùng trong $TARGET_FILE không khớp với kết quả của 'tail -n 5 $SOURCE_LOG'."
    exit 1
fi

echo "[SUCCESS] Tuyệt vời! Bạn đã trích xuất chính xác 10 dòng dữ liệu nhật ký bằng sự kết hợp nhuần nhuyễn giữa 'head', 'tail' và các toán tử chuyển hướng (>, >>)."
exit 0
