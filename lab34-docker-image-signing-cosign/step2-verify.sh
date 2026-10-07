#!/bin/bash

TAGS_JSON=$(curl -s http://localhost:5000/v2/order-service/tags/list 2>/dev/null)

if ! echo "$TAGS_JSON" | grep -q '"v1.0"'; then
  echo "Chua day image localhost:5000/order-service:v1.0 len Registry."
  exit 1
fi

if ! echo "$TAGS_JSON" | grep -q '\.sig'; then
  echo "Chua thuc hien ky so Cosign len image (chua co artifact .sig tren Registry)."
  exit 1
fi

echo "Buoc 2 da hoan thanh thanh cong!"
exit 0
