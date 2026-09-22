#!/bin/bash

TARGET_FILE="/tmp/subnet.txt"

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Chưa tìm thấy file $TARGET_FILE. Hãy ghi prefix CIDR của bạn vào file này (ví dụ: echo \"27\" > /tmp/subnet.txt)."
    exit 1
fi

CONTENT=$(cat "$TARGET_FILE" | tr -d '[:space:]')

if [[ "$CONTENT" =~ ^(/)?27$ ]] || [[ "$CONTENT" =~ /27$ ]]; then
    echo "✅ Chính xác! Subnet mask CIDR /27 (255.255.255.224) cung cấp 30 IP khả dụng (2^5 - 2 = 30), tối ưu nhất cho 25 containers."
    exit 0
else
    echo "❌ Kết quả '$CONTENT' chưa chính xác. Gợi ý: Hãy tìm số mũ h nhỏ nhất sao cho (2^h - 2 >= 25), sau đó lấy 32 - h."
    exit 1
fi
