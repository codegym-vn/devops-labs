#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 31: Tich Hop OWASP ZAP Quet DAST    "
echo "================================================================"
echo "Dang khoi tao ung dung Web muc tieu va cong cu OWASP ZAP..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Moi truong thuc hanh da san sang!"
echo "Thu muc ung dung: /root/dast-target-app"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/dast-target-app
