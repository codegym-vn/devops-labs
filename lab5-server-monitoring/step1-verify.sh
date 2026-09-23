#!/bin/bash

# Kiem tra file /root/monitor.sh ton tai
if [ ! -f /root/monitor.sh ]; then
    echo "[ERROR] File /root/monitor.sh khong ton tai. Hay tao script tai duong dan nay."
    exit 1
fi

# Kiem tra quyen thuc thi
if [ ! -x /root/monitor.sh ]; then
    echo "[ERROR] File /root/monitor.sh chua co quyen thuc thi. Hay chay lenh: chmod +x /root/monitor.sh"
    exit 1
fi

# Chay thu script va lay output
OUTPUT=$(/root/monitor.sh 2>&1)

# Kiem tra dinh dang output: CPU: <so>% | RAM: <so>% | DISK: <so>%
if echo "$OUTPUT" | grep -qiE "CPU:[[:space:]]*[0-9]+(\.[0-9]+)?%[[:space:]]*\|[[:space:]]*RAM:[[:space:]]*[0-9]+(\.[0-9]+)?%[[:space:]]*\|[[:space:]]*DISK:[[:space:]]*[0-9]+(\.[0-9]+)?%"; then
    echo "[SUCCESS] Script monitor.sh hoat dong dung! Output thuc te: $OUTPUT"
    exit 0
else
    echo "[ERROR] Output cua script chua dung dinh dang yeu cau."
    echo "Dinh dang mong doi: CPU: <value>% | RAM: <value>% | DISK: <value>%"
    echo "Dau ra thuc te cua script: $OUTPUT"
    exit 1
fi
