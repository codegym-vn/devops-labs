#!/bin/bash

# Kiem tra container loki dang chay
if [ -z "$(docker ps -q -f name=loki)" ]; then
  echo "Container loki chua duoc khoi chay."
  exit 1
fi

# Kiem tra container fluent-bit dang chay
if [ -z "$(docker ps -q -f name=fluent-bit)" ]; then
  echo "Container fluent-bit chua duoc khoi chay."
  exit 1
fi

# Kiem tra container grafana dang chay
if [ -z "$(docker ps -q -f name=grafana)" ]; then
  echo "Container grafana chua duoc khoi chay."
  exit 1
fi

# Kiem tra trang thai ready cua Loki
READY=$(curl -s http://localhost:3100/ready 2>/dev/null)
if ! echo "$READY" | grep -q "ready"; then
  echo "Dich vu Loki chua san sang tiep nhan yeu cau."
  exit 1
fi

# Kiem tra nhan service da duoc phan vung trong Loki
LABELS=$(curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null)
if ! echo "$LABELS" | grep -q '"service"'; then
  echo "Loki chua nhan duoc nhan service tu Fluent Bit routing."
  exit 1
fi

# Kiem tra file loki-routing-labels.json
if [ ! -f /root/centralized-logging-lab/loki-routing-labels.json ]; then
  echo "Chua tim thay tep /root/centralized-logging-lab/loki-routing-labels.json."
  exit 1
fi

echo "Buoc 3 da hoan thanh xuat sac!"
exit 0
