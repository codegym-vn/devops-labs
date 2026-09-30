#!/bin/bash
# background.sh — Lab 19: Kubernetes Cluster & Node Management via kubectl

echo "Khởi tạo môi trường Kubernetes 2 Nodes..." > /tmp/lab-status.log

# 1. Thiết lập biến môi trường Kubeconfig
export KUBECONFIG=/root/.kube/config
mkdir -p /root/.kube 2>/dev/null

# 2. Chờ cả 2 Node (controlplane và node01) đạt trạng thái Ready
echo "Đang chờ các Node trong cụm K8s đạt trạng thái Ready..." > /tmp/lab-status.log
MAX_RETRY=60
RETRY=0

while [ $RETRY -lt $MAX_RETRY ]; do
  READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
  if [ "$READY_NODES" -ge 2 ]; then
    break
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

# 3. Cấu hình tiện ích alias k và tự động hoàn thành lệnh (Autocomplete)
cat << 'EOF' >> /root/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k 2>/dev/null || true
source <(kubectl completion bash 2>/dev/null) 2>/dev/null || true
EOF

# 4. Chuẩn bị thư mục làm việc chính
mkdir -p /root/k8s-lab
cd /root/k8s-lab

echo "Cụm Kubernetes 2 Nodes đã sẵn sàng!" > /tmp/lab-status.log
touch /tmp/.lab_ready
