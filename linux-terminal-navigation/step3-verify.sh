#!/bin/bash

BASE_DIR="/root/devops-workspace"

if [ ! -d "$BASE_DIR" ]; then
    echo "[ERROR] Thư mục gốc $BASE_DIR chưa tồn tại. Hãy dùng lệnh 'mkdir -p $BASE_DIR' để bắt đầu."
    exit 1
fi

REQUIRED_DIRS=(
    "$BASE_DIR/app/src"
    "$BASE_DIR/app/configs"
    "$BASE_DIR/backups"
    "$BASE_DIR/logs"
)

for d in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$d" ]; then
        echo "[ERROR] Thiếu thư mục bắt buộc: $d. Hãy kiểm tra lại cấu trúc bằng lệnh 'tree $BASE_DIR'."
        exit 1
    fi
done

REQUIRED_FILES=(
    "$BASE_DIR/app/src/main.py"
    "$BASE_DIR/app/configs/app.env"
    "$BASE_DIR/backups/app.env.bak"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] Thiếu file bắt buộc: $f. Hãy kiểm tra lại các bước tạo và sao chép file."
        exit 1
    fi
done

if [ -d "$BASE_DIR/temp-scratch" ]; then
    echo "[ERROR] Thư mục rác $BASE_DIR/temp-scratch vẫn còn tồn tại. Hãy dùng lệnh 'rm -r' để xóa nó theo yêu cầu."
    exit 1
fi

echo "[SUCCESS] Xuất sắc! Toàn bộ kiến trúc thư mục DevOps Workspace đã được khởi tạo chuẩn hóa, các file cấu hình và backup đã được bố trí chính xác 100%."
exit 0
