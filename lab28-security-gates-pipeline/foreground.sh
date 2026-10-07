#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 28: CI/CD Security Gates           "
echo "================================================================"
echo "Dang khoi tao cong cu Trivy, Gitleaks va kho ma nguon..."

while [ ! -f /tmp/background-finished ]; do
  printf "."
  sleep 1
done

echo ""
echo "[OK] Cong cu Trivy va Gitleaks da san sang!"
echo "Thu muc thuc hanh: /root/security-gate-lab"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/security-gate-lab
