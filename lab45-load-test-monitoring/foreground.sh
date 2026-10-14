#!/bin/bash
echo "Dang khoi dong he thong Target API, Prometheus va Grafana Correlation Dashboard..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 45 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "================================================================================"
echo "  LAB 45: CORRELATE LOAD TEST VOI MONITORING (PROMETHEUS & GRAFANA)             "
echo "  Moi truong: Ubuntu Linux | Port: 8080 (App), 9090 (Prometheus), 3000 (Grafana)"
echo "================================================================================"
echo "  Thong tin he thong san sang:                                                  "
echo "    - Target API:          http://localhost:8080/health                         "
echo "    - Prometheus Server:   http://localhost:9090 (Scrape interval: 2s)          "
echo "    - Grafana Dashboard:   http://localhost:3000 (Load & System Correlation)   "
echo "    - Thu muc du an:       /root/load-monitoring-lab                            "
echo "================================================================================"
echo "  Chuyen vao thu muc du an va thuc hien cac yeu cau tai Step 1.                "
echo "================================================================================"
cd /root/load-monitoring-lab
