#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 37: Centralized Logging Pipeline"
echo "================================================================"
echo "Dang khoi tao moi truong va tai cac container can thiet..."

while [ ! -f /tmp/background-finished ]; do
  sleep 1
done

echo ""
echo "[OK] Moi truong thuc hanh da san sang tai: /root/centralized-logging-lab"
echo "Hay lam theo huong dan ben trai de bat dau."
echo "================================================================"
mkdir -p /root/centralized-logging-lab
cd /root/centralized-logging-lab
