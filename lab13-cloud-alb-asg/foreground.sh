#!/bin/bash
echo ""
echo "⏳ Đang khởi động LocalStack (ALB & Auto Scaling) và chuẩn bị mạng đa phân vùng (Multi-AZ)..."
while [ ! -f /tmp/.lab_ready ]; do
  sleep 1
done

echo ""
echo "✅ Môi trường LocalStack đã sẵn sàng!"
echo "💡 VPC và 2 Subnet ở 2 Availability Zones (us-east-1a, us-east-1b) đã được khởi tạo sẵn."
echo ""
aws --version
echo ""
