#!/bin/bash
echo "Dang khoi tao moi truong Grafana, Prometheus va Ecommerce API, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 35 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 42: Xay Dung Monitoring Dashboard Grafana "
echo "  He thong da san sang:                                           "
echo "    • Grafana Web UI:    http://localhost:3000 (admin / admin)    "
echo "    • Prometheus Web:    http://localhost:9090                    "
echo "    • Node Exporter:     http://localhost:9100/metrics            "
echo "    • Ecommerce API:     http://localhost:8080/metrics            "
echo "    • Thu muc lam viec:  /root/grafana-lab                        "
echo "=================================================================="
cd /root/grafana-lab
