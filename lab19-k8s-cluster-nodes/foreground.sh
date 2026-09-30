#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: Quản Trị Cụm Kubernetes 2 Nodes Qua kubectl"
echo "================================================================"
echo ""

STATUS_FILE="/tmp/lab-status.log"
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0

while [ ! -f /tmp/.lab_ready ]; do
  if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
  else
    STATUS="Đang chuẩn bị cụm Kubernetes..."
  fi
  idx=$((i % ${#spinner[@]}))
  printf "\r\033[K %s %s" "${spinner[$idx]}" "$STATUS"
  sleep 0.5
  i=$((i + 1))
done

printf "\r\033[K ✅ Cụm Kubernetes 2 Nodes đã sẵn sàng!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thông tin môi trường:"
echo "   - Cụm gồm 2 Nodes : controlplane (Master) & node01 (Worker)"
echo "   - Tiện ích có sẵn : Lệnh 'kubectl' hoặc gõ tắt 'k'"
echo "   - Thư mục thực hành: /root/k8s-lab"
echo "----------------------------------------------------------------"
echo ""

if command -v kubectl >/dev/null 2>&1; then
  echo "📊 Trạng thái các Node hiện tại:"
  kubectl get nodes
fi

cd /root/k8s-lab 2>/dev/null || true
echo ""
