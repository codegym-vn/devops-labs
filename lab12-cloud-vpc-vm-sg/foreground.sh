#!/bin/bash
echo ""
echo "⏳ Đang khởi động LocalStack (AWS Cloud Simulator) và AWS CLI..."
while [ ! -f /tmp/.lab_ready ]; do
  sleep 1
done

echo ""
echo "✅ LocalStack & AWS CLI đã sẵn sàng!"
echo "💡 Bạn có thể dùng lệnh 'aws' hoặc 'awslocal' trực tiếp (đã cấu hình sẵn Endpoint http://localhost:4566)."
echo ""
aws --version
echo ""
