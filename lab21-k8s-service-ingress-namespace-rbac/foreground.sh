#!/bin/bash
clear
echo "================================================================"
echo " 🚀 DevOps Labs: Services, Ingress, Namespaces & RBAC"
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

printf "\r\033[K ✅ Cum Kubernetes 2 Nodes da san sang!\n\n"
echo "----------------------------------------------------------------"
echo "💡 Thong tin moi truong:"
echo "   - Cum gom 2 Nodes : controlplane (Master) & node01 (Worker)"
echo "   - Tien ich co san : Lenh 'kubectl' hoac go tat 'k'"
echo "   - Thu muc thuc hanh: /root/k8s-networking"
echo "----------------------------------------------------------------"
echo ""

if command -v kubectl >/dev/null 2>&1; then
  echo "📊 Trang thai cac Node hien tai:"
  kubectl get nodes
fi

cd /root/k8s-networking 2>/dev/null || true
echo ""
