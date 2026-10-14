#!/bin/bash
echo "Dang khoi tao moi truong Prometheus, Alertmanager va Webhook Receiver, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 35 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "=================================================================="
echo "  Chao mung den voi Lab 43: Thiet Lap Canh Bao (Alerting)        "
echo "  He thong da san sang:                                           "
echo "    • Prometheus Web:    http://localhost:9090                    "
echo "    • Alertmanager Web:  http://localhost:9093                    "
echo "    • Webhook Receiver:  http://localhost:5001/webhook            "
echo "    • CLI Tools:         promtool, amtool                         "
echo "    • Thu muc lam viec:  /root/alerting-lab                       "
echo "=================================================================="
cd /root/alerting-lab
