#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: Khởi tạo môi trường Cloud (AWS & LocalStack)"
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

printf "\r\033[K ✅ Môi trường Cloud & AWS CLI đã sẵn sàng!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thông tin môi trường:"
echo "   - AWS Endpoint : http://localhost:4566 (LocalStack)"
echo "   - Default Region: us-east-1"
echo "   - Lệnh sử dụng : aws [command] hoặc awslocal [command]"
echo "----------------------------------------------------------------"
echo ""

if command -v aws >/dev/null 2>&1; then
  aws --version 2>/dev/null || true
fi
echo ""
