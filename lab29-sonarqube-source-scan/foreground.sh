#!/bin/bash

echo "================================================================"
echo "  Chao mung ban den voi Lab 29: Cau Hinh SonarQube Quet Ma Nguon"
echo "================================================================"
echo "Dang khoi tao he thong va tai cac goi can thiet..."

STAGE_FILE="/tmp/init-stage.log"
LAST_LINE=""

while [ ! -f /tmp/background-finished ]; do
  if [ -f "$STAGE_FILE" ]; then
    CURRENT_LINE=$(tail -n 1 "$STAGE_FILE" 2>/dev/null || true)
    if [ -n "$CURRENT_LINE" ] && [ "$CURRENT_LINE" != "$LAST_LINE" ]; then
      echo ">>> $CURRENT_LINE"
      LAST_LINE="$CURRENT_LINE"
    fi
  fi
  printf "."
  sleep 2
done

echo ""
echo "[OK] SonarQube Server va SonarScanner CLI da san sang!"
echo "Thu muc du an: /root/sonarqube-lab"
echo "Chuc ban thuc hanh thanh cong!"
echo "================================================================"
cd /root/sonarqube-lab
