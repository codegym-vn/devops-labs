#!/bin/bash
set -e

DS_FILE="/root/grafana-lab/provisioning/datasources/prometheus-datasource.yml"

# 1. Kiem tra tep provisioning ton tai
if [ ! -f "$DS_FILE" ]; then
  echo "Loi: Chua tim thay tep cau hinh $DS_FILE!"
  echo "Goi y: Hay tao tep theo huong dan o Buoc 1."
  exit 1
fi

# 2. Kiem tra noi dung co khai bao prometheus va localhost:9090
if ! grep -q "type: prometheus" "$DS_FILE" || ! grep -q "http://localhost:9090" "$DS_FILE"; then
  echo "Loi: Noi dung $DS_FILE chua dung dinh dang yeu cau (can co 'type: prometheus' va 'url: http://localhost:9090')!"
  exit 1
fi

# 3. Kiem tra Grafana REST API da nap datasource thanh cong chua
# Thu reload neu chua nhan
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/datasources/reload > /dev/null 2>&1 || true
sleep 1

DATASOURCES=$(curl -s -u admin:admin http://localhost:3000/api/datasources 2>/dev/null || echo "[]")
HAS_PROM=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="prometheus") | .name' 2>/dev/null || echo "")

if [ -z "$HAS_PROM" ]; then
  # Thu khoi dong lai container Grafana neu can
  docker restart grafana > /dev/null 2>&1
  sleep 4
  DATASOURCES=$(curl -s -u admin:admin http://localhost:3000/api/datasources 2>/dev/null || echo "[]")
  HAS_PROM=$(echo "$DATASOURCES" | jq -r '.[] | select(.type=="prometheus") | .name' 2>/dev/null || echo "")
fi

if [ -z "$HAS_PROM" ]; then
  echo "Loi: Grafana chua nap duoc Data Source Prometheus qua API /api/datasources!"
  echo "Chi tiet datasources hien tai: $DATASOURCES"
  exit 1
fi

echo "[XAC THUC THANH CONG] Grafana da nap thanh cong Data Source Prometheus ($HAS_PROM) qua co che Provisioning!"
exit 0
