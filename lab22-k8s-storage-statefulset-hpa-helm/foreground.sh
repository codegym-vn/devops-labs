#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: StorageClass, StatefulSet, HPA & Helm"
echo "================================================================"
echo ""

STATUS_FILE="/tmp/lab-status.log"
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0

while [ ! -f /tmp/.lab_ready ]; do
  if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
  else
    STATUS="Dang chuan bi cum Kubernetes..."
  fi
  idx=$((i % ${#spinner[@]}))
  printf "\r\033[K %s %s" "${spinner[$idx]}" "$STATUS"
  sleep 0.5
  i=$((i + 1))
done

printf "\r\033[K ✅ Cum Kubernetes da san sang!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thong tin moi truong:"
echo "   - Cum gom 2 Nodes : controlplane (Master) & node01 (Worker)"
echo "   - Cong cu san co  : kubectl (alias k), helm 3, metrics-server"
echo "   - StorageClass    : local-path (mac dinh)"
echo "   - Thu muc thuc hanh: /root/k8s-advanced"
echo "----------------------------------------------------------------"
echo ""

if command -v kubectl >/dev/null 2>&1; then
  echo "📊 Trang thai cac Node hien tai:"
  kubectl get nodes
fi

cd /root/k8s-advanced 2>/dev/null || true
echo ""
