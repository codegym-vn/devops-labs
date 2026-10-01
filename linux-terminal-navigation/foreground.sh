#!/bin/bash
echo "Đang chuẩn bị môi trường thực hành Terminal, vui lòng chờ trong giây lát..."
while [ ! -f /tmp/.lab_ready ]; do sleep 1; done
echo "Hệ thống đã sẵn sàng! Bạn có thể bắt đầu gõ lệnh."
