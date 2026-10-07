#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 25: IaC Security (Checkov & Tfsec) "
echo "================================================================"
echo "Dang khoi tao cong cu Checkov va Tfsec..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Cong cu tfsec va checkov da san sang!"
echo "Thu muc thuc hanh: /root/iac-security-lab"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/iac-security-lab
