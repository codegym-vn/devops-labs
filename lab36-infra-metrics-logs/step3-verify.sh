#!/bin/bash

# Kiem tra container loki dang chay
if [ -z "$(docker ps -q -f name=loki)" ]; then
  echo "Container loki chua duoc khoi chay."
  exit 1
fi

# Kiem tra container promtail dang chay
if [ -z "$(docker ps -q -f name=promtail)" ]; then
  echo "Container promtail chua duoc khoi chay."
  exit 1
fi

# Kiem tra trang thai ready cua Loki
READY=$(curl -s http://localhost:3100/ready 2>/dev/null)
if ! echo "$READY" | grep -q "ready"; then
  echo "Dich vu Loki chua san sang tiep nhan yeu cau."
  exit 1
fi

# Kiem tra nhan da xuat hien trong Loki
LABELS=$(curl -s http://localhost:3100/loki/api/v1/labels 2>/dev/null)
if ! echo "$LABELS" | grep -q '"job"'; then
  echo "Loki chua nhan duoc nhan job tu Promtail shipper."
  exit 1
fi

# Kiem tra file loki-labels.json
if [ ! -f /root/infra-monitoring-lab/loki-labels.json ]; then
  echo "Chua tim thay tep /root/infra-monitoring-lab/loki-labels.json."
  exit 1
fi

echo "Buoc 3 da hoan thanh xuat sac!"
exit 0
