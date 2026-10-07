#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 29: Cau Hinh SonarQube Quet Ma Nguon"
echo "================================================================"
echo "Dang khoi tao SonarQube Server va cai dat SonarScanner CLI..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Moi truong thuc hanh da san sang!"
echo "Thu muc du an: /root/sonarqube-lab"
echo "SonarQube Server dang khoi dong tren port 9000."
echo "================================================================"
cd /root/sonarqube-lab
