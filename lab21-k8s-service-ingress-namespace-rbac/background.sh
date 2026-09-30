#!/bin/bash
# background.sh — Lab 21: Services, Ingress, Namespaces and RBAC

echo "Khoi tao moi truong Kubernetes cho Lab 21..." > /tmp/lab-status.log

# 1. Thiet lap Kubeconfig
export KUBECONFIG=/root/.kube/config
mkdir -p /root/.kube 2>/dev/null

# 2. Cho ca 2 Nodes (controlplane va node01) dat trang thai Ready
echo "Dang cho cac Node trong cum K8s dat trang thai Ready..." > /tmp/lab-status.log
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

# 3. Cai dat Ingress Nginx Controller trong che do baremetal (chay ngam)
(
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml 2>/dev/null || true
) &

# 4. Cau hinh tien ich alias k va auto-completion
cat << 'EOF' >> /root/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k 2>/dev/null || true
source <(kubectl completion bash 2>/dev/null) 2>/dev/null || true
EOF

# 5. Chuan bi thu muc thuc hanh
mkdir -p /root/k8s-networking
cd /root/k8s-networking

echo "Moi truong Lab 21 da san sang!" > /tmp/lab-status.log
touch /tmp/.lab_ready
