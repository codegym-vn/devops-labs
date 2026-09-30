#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: Thực Hành Terraform CLI & Cloud IaC"
echo "================================================================"
echo ""

STATUS_FILE="/tmp/lab-status.log"
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0

while [ ! -f /tmp/.lab_ready ]; do
  if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
  else
    STATUS="Đang chuẩn bị hệ thống..."
  fi
  idx=$((i % ${#spinner[@]}))
  printf "\r\033[K %s %s" "${spinner[$idx]}" "$STATUS"
  sleep 0.5
  i=$((i + 1))
done

printf "\r\033[K ✅ Môi trường Terraform CLI & Cloud đã sẵn sàng!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thông tin môi trường:"
echo "   - Thư mục làm việc: /root/terraform-lab"
echo "   - Cloud Backend   : LocalStack (http://localhost:4566)"
echo "   - Region          : us-east-1"
echo "   - Editor          : Xem và sửa code trực quan qua File Explorer bên trái"
echo "----------------------------------------------------------------"
echo ""

if command -v terraform >/dev/null 2>&1; then
  terraform version | head -n 1
fi

if command -v aws >/dev/null 2>&1; then
  aws --version 2>/dev/null || true
fi

cd /root/terraform-lab 2>/dev/null || cd /home/ubuntu/terraform-lab 2>/dev/null || true
echo ""
