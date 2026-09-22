#!/bin/bash

# Kiểm tra xem cổng 8080 có đang ở trạng thái LISTEN bằng lệnh ss không
if ss -tlpn 2>/dev/null | grep -E -q ':(8080)\b'; then
    echo "[SUCCESS] Cổng 8080 đang ở trạng thái LISTEN và sẵn sàng tiếp nhận kết nối TCP."
    exit 0
else
    echo "[ERROR] Chưa phát hiện tiến trình nào đang lắng nghe trên cổng 8080. Hãy chạy lệnh khởi động mock service theo hướng dẫn và bấm Check lại."
    exit 1
fi
