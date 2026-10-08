#!/bin/bash

if ! curl -s http://localhost:3000/health | grep -q '"status":"UP"'; then
  echo "Ung dung server.js chua khoi chay thanh cong tren cong 3000."
  exit 1
fi

METRICS=$(curl -s http://localhost:3000/metrics 2>/dev/null)

if ! echo "$METRICS" | grep -q "nodejs_heap_size_used_bytes"; then
  echo "Endpoint /metrics chua hoat dong hoac chua co Default Metrics cua prom-client."
  exit 1
fi

echo "Buoc 1 da hoan thanh thanh cong!"
exit 0
