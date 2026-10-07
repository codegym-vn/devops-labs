#!/bin/bash
set -e

# Đợi cụm Kubernetes khởi động và các node sẵn sàng
while ! kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  sleep 2
done

# Tạo thư mục thực hành
mkdir -p /root/canary-lab

# Thiết lập alias và autocomplete
if ! grep -q "alias k=kubectl" /root/.bashrc; then
  echo "alias k=kubectl" >> /root/.bashrc
  echo "source <(kubectl completion bash)" >> /root/.bashrc
  echo "complete -o default -F __start_kubectl k" >> /root/.bashrc
fi

# Tải trước các image cần thiết để tiết kiệm thời gian
docker pull nginxdemos/hello:plain-text > /dev/null 2>&1 &
docker pull curlimages/curl:latest > /dev/null 2>&1 &

wait

# Đánh dấu hoàn tất chuẩn bị
touch /tmp/background-finished
