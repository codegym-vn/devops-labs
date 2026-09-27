#!/bin/bash
# foreground.sh — Hiển thị trạng thái chờ môi trường sẵn sàng
echo ""
echo "⏳ Đang khởi tạo môi trường Lab..."
echo "   → Cài đặt LocalStack, AWS CLI và Docker"
echo ""

SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
i=0
while [ ! -f /tmp/lab-ready ]; do
  printf "\r   %s  Đang khởi động LocalStack..." "${SPIN[$i % 10]}"
  sleep 0.3
  i=$((i + 1))
done

echo ""
echo ""
echo "✅ Môi trường đã sẵn sàng!"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│                  Lab 12 — Cloud VPC                  │"
echo "│                                                       │"
echo "│  LocalStack  : http://localhost:4566                  │"
echo "│  AWS CLI     : đã cấu hình sẵn (alias aws)           │"
echo "│  Docker      : đang chạy                             │"
echo "│                                                       │"
echo "│  Kiểm tra trạng thái: lab-status                     │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "👉 Nhấn CONTINUE để bắt đầu Bước 1"
