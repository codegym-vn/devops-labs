#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 20: Pods, Deployments & Probes     "
echo "================================================================"
echo "Dang kiem tra tinh san sang cua cum Kubernetes..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Cum Kubernetes da san sang!"
echo "[OK] Alias 'k' va auto-completion da duoc cau hinh san."
echo "Thu muc thuc hanh: /root/k8s-workloads"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
