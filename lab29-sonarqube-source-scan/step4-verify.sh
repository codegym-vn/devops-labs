#!/bin/bash
set -e

# 1. Kiem tra tep check-quality-gate.sh
if [ ! -f /root/sonarqube-lab/check-quality-gate.sh ]; then
  echo "Loi: Tep /root/sonarqube-lab/check-quality-gate.sh khong ton tai!"
  exit 1
fi

if [ ! -x /root/sonarqube-lab/check-quality-gate.sh ]; then
  echo "Loi: Tep check-quality-gate.sh chua duoc cap quyen thuc thi (chmod +x)!"
  exit 1
fi

# 2. Chay thu nghiem script
OUTPUT=$(/root/sonarqube-lab/check-quality-gate.sh 2>&1)
if ! echo "$OUTPUT" | grep -q "GATE PASSED"; then
  echo "Loi: Script check-quality-gate.sh khong tra ve GATE PASSED! Chi tiet: $OUTPUT"
  exit 1
fi

echo "Kiem tra Cổng chat luong Quality Gate tu dong thanh cong!"
exit 0
