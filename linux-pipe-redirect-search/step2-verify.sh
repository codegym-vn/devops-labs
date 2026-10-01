#!/bin/bash

COUNT_FILE="/tmp/error-count.txt"
LOG_FILE="/tmp/filtered-errors.log"

if [ ! -f "$COUNT_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $COUNT_FILE."
    exit 1
fi

COUNT_VAL=$(cat "$COUNT_FILE" | tr -d '[:space:]')
if [ "$COUNT_VAL" != "12" ]; then
    echo "[ERROR] Số lượng lỗi trong $COUNT_FILE là '$COUNT_VAL', mong đợi là '12'. Hãy kiểm tra lại biểu thức lọc grep."
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file lưu vết lỗi $LOG_FILE. Hãy sử dụng lệnh tee trong pipeline để ghi file này."
    exit 1
fi

ACTUAL_LINES=$(wc -l < "$LOG_FILE" | tr -d '[:space:]')
if [ "$ACTUAL_LINES" -ne 12 ]; then
    echo "[ERROR] File $LOG_FILE hiện có $ACTUAL_LINES dòng, mong đợi đúng 12 dòng."
    exit 1
fi

if grep -q -v -E " (404|500) " "$LOG_FILE"; then
    echo "[ERROR] Trong $LOG_FILE có lẫn các dòng không chứa mã trạng thái 404 hoặc 500."
    exit 1
fi

echo "[SUCCESS] Xuất sắc! Chuỗi đường ống (Pipeline) kết hợp grep, tee và wc đã lọc chuẩn xác 12 sự cố và trích xuất dữ liệu thành công."
exit 0
