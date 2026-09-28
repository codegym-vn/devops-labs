#!/bin/bash
echo ""
echo "⏳ Đang chuẩn bị môi trường FinOps, LocalStack EC2 và tập dữ liệu chi phí 30 ngày..."
while [ ! -f /tmp/.lab_ready ]; do
  sleep 1
done

echo ""
echo "✅ Môi trường FinOps & AWS CLI đã sẵn sàng!"
echo "💡 5 máy ảo EC2 đại diện cho các phòng ban đã được tạo trên LocalStack."
echo ""
aws --version
echo ""
