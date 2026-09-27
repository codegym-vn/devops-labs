#!/bin/bash
echo ""
echo "⏳ Đang khởi tạo môi trường Lab 13..."
echo "   → LocalStack, AWS CLI, Docker, Nginx"
echo ""
SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
i=0
while [ ! -f /tmp/lab-ready ]; do
  printf "\r   %s  Đang khởi động dịch vụ..." "${SPIN[$i % 10]}"
  sleep 0.3; i=$((i + 1))
done
echo ""
echo ""
echo "✅ Môi trường đã sẵn sàng!"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│              Lab 13 — ALB + Auto Scaling             │"
echo "│                                                       │"
echo "│  LocalStack  : http://localhost:4566                  │"
echo "│  VPC + Subnets: đã tạo sẵn (2 AZ)                   │"
echo "│  Nginx       : đang chạy (làm LB thật)               │"
echo "│                                                       │"
echo "│  Kiểm tra: lab-status                                │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "👉 Nhấn CONTINUE để bắt đầu Bước 1"
