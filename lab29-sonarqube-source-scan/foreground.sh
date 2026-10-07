#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 29: Cau Hinh SonarQube Quet Ma Nguon"
echo "================================================================"
echo "Thu muc thuc hanh: /root/sonarqube-lab"
echo "Dich vu SonarQube dang duoc khoi dong ngam."
echo "Hay lam theo cac buoc huong dan ben trai de bat dau!"
echo "================================================================"

while [ ! -f /tmp/background-finished ]; do
  sleep 0.5
done

cd /root/sonarqube-lab
