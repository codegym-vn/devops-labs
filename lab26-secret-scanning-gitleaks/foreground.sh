#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 26: Secret Scanning (Gitleaks)     "
echo "================================================================"
echo "Dang kiem tra va khoi tao moi truong..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Cong cu Gitleaks va kho ma nguon mau da san sang!"
echo "Thu muc thuc hanh: /root/secret-leak-lab"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/secret-leak-lab
