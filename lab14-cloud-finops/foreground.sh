#!/bin/bash
echo ""
echo "⏳ Đang khởi tạo môi trường Lab 14 — FinOps..."
SPIN=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
i=0
while [ ! -f /tmp/lab-ready ]; do
  printf "\r   %s  Đang chuẩn bị dataset và tài nguyên mẫu..." "${SPIN[$i % 10]}"
  sleep 0.3; i=$((i + 1))
done
echo ""
echo ""
echo "✅ Môi trường FinOps đã sẵn sàng!"
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│                Lab 14 — FinOps                       │"
echo "│                                                       │"
echo "│  Tài nguyên mẫu : 5 EC2 instances đã tạo sẵn        │"
echo "│  Dataset CUR    : /opt/lab-data/cost-usage-report.csv│"
echo "│  Utilization    : /opt/lab-data/resource-utilization.json │"
echo "│                                                       │"
echo "│  Kiểm tra: lab-status                                │"
echo "└─────────────────────────────────────────────────────┘"
echo ""
echo "👉 Nhấn CONTINUE để bắt đầu Bước 1"
