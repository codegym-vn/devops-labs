#!/bin/bash
echo ""
echo "⏳ Đang khởi tạo môi trường..."
while [ ! -f /tmp/.lab_ready ]; do
  sleep 1
done
echo " Môi trường sẵn sàng! Có thể tiếp tục bài thực hành."
