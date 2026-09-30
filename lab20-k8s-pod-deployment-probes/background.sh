#!/bin/bash
set -e

# Đợi cụm Kubernetes khởi động và các node sẵn sàng
while ! kubectl get nodes | grep -q "Ready"; do
  sleep 2
done

# Tạo thư mục thực hành
mkdir -p /root/k8s-workloads

# Thiết lập tiện ích alias và autocomplete
if ! grep -q "alias k=kubectl" /root/.bashrc; then
  echo "alias k=kubectl" >> /root/.bashrc
  echo "source <(kubectl completion bash)" >> /root/.bashrc
  echo "complete -o default -F __start_kubectl k" >> /root/.bashrc
fi

# Đánh dấu hoàn tất chuẩn bị
touch /tmp/background-finished
