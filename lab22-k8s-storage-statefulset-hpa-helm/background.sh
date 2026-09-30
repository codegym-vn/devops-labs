#!/bin/bash
# background.sh — Lab 22: StorageClass, StatefulSet, HPA and Helm Chart

echo "Khoi tao moi truong Kubernetes cho Lab 22..." > /tmp/lab-status.log

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

# 3. Cai dat Local-Path StorageClass cho cap phat dong (Dynamic Provisioning)
echo "Dang thiet lap Dynamic StorageClass (local-path)..." > /tmp/lab-status.log
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml 2>/dev/null || true
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' 2>/dev/null || true

# 4. Cai dat Metrics-Server cho HPA (Horizontal Pod Autoscaler)
echo "Dang cai dat Metrics-Server..." > /tmp/lab-status.log
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null || true
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' 2>/dev/null || true

# 5. Cai dat Helm 3 neu chua co
if ! command -v helm >/dev/null 2>&1; then
  echo "Dang cai dat Helm 3..." > /tmp/lab-status.log
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null || true
fi

# 6. Cau hinh tien ich alias k va auto-completion
cat << 'EOF' >> /root/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k 2>/dev/null || true
source <(kubectl completion bash 2>/dev/null) 2>/dev/null || true
EOF

# 7. Chuan bi thu muc thuc hanh
mkdir -p /root/k8s-advanced
cd /root/k8s-advanced

echo "Moi truong Lab 22 da san sang!" > /tmp/lab-status.log
touch /tmp/.lab_ready
