#!/bin/bash

while [ ! -f /tmp/background-finished ]; do
  sleep 0.2
done

echo "================================================================"
echo "  Chao mung ban den voi Lab 29: Cau Hinh SonarQube Quet Ma Nguon"
echo "================================================================"
echo "Thu muc thuc hanh: /root/sonarqube-lab"
echo "Moi truong da san sang! Hay lam theo huong dan ben trai de bat dau."
echo "================================================================"
cd /root/sonarqube-lab
