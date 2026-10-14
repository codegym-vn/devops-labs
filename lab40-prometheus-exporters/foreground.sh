#!/bin/bash
echo "Dang chuan bi moi truong Prometheus va cac Exporters, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 30 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 40: Cau Hinh Prometheus Va Exporters     "
echo "  Moi truong thu thap Metrics da san sang tai: /root/prometheus-lab"
echo "=================================================================="
cd /root/prometheus-lab
