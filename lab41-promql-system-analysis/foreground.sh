#!/bin/bash
echo "Dang khoi tao moi truong Prometheus, Node Exporter va Ecommerce API, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 35 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 41: Phan Tich He Thong Bang PromQL        "
echo "  He thong da san sang:                                           "
echo "    • Prometheus Web UI: http://localhost:9090                   "
echo "    • Node Exporter:     http://localhost:9100/metrics           "
echo "    • Ecommerce API:     http://localhost:8080/metrics           "
echo "    • Traffic Generator: Dang sinh luong request lien tuc!       "
echo "=================================================================="
cd /root/promql-lab
