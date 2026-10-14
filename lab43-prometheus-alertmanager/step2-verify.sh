#!/bin/bash
set -e

AM_FILE="/root/alerting-lab/alertmanager.yml"

# 1. Kiem tra tep alertmanager.yml ton tai
if [ ! -f "$AM_FILE" ]; then
  echo "Loi: Chua tim thay tep cau hinh $AM_FILE!"
  echo "Goi y: Hay tao tep theo huong dan o Buoc 2."
  exit 1
fi

# 2. Kiem tra cu phap bang amtool
if ! amtool check-config "$AM_FILE" > /dev/null 2>&1; then
  echo "Loi: Cu phap cua tep $AM_FILE khong hop le theo amtool!"
  exit 1
fi

# 3. Kiem tra noi dung co routes va receivers
if ! grep -q "receiver:" "$AM_FILE" || ! grep -q "receivers:" "$AM_FILE"; then
  echo "Loi: Tep $AM_FILE chua dinh nghia receiver hoac danh sach receivers hop le!"
  exit 1
fi

# 4. Kiem tra Prometheus da ket noi toi Alertmanager chua
curl -s -X POST http://localhost:9093/-/reload > /dev/null 2>&1 || true
sleep 1

AM_ACTIVE=$(curl -s http://localhost:9090/api/v1/alertmanagers 2>/dev/null | jq -r '.data.activeAlertmanagers | length' 2>/dev/null || echo "0")
if [ "$AM_ACTIVE" -eq 0 ]; then
  # Thu reload Prometheus
  curl -s -X POST http://localhost:9090/-/reload > /dev/null 2>&1 || true
  sleep 2
  AM_ACTIVE=$(curl -s http://localhost:9090/api/v1/alertmanagers 2>/dev/null | jq -r '.data.activeAlertmanagers | length' 2>/dev/null || echo "0")
fi

if [ "$AM_ACTIVE" -eq 0 ]; then
  echo "Loi: Prometheus chua ket noi duoc voi Alertmanager tren cong 9093!"
  exit 1
fi

echo "[XAC THUC THANH CONG] Alertmanager da duoc cau hinh hop le va Prometheus da ket noi thanh cong ($AM_ACTIVE active)!"
exit 0
