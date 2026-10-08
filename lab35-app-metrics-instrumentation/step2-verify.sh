#!/bin/bash

METRICS=$(curl -s http://localhost:3000/metrics 2>/dev/null)

if ! echo "$METRICS" | grep -q "http_requests_total"; then
  echo "Chua tim thay custom metric Counter: http_requests_total tai /metrics."
  exit 1
fi

if ! echo "$METRICS" | grep -q "http_request_duration_seconds_bucket"; then
  echo "Chua tim thay custom metric Histogram: http_request_duration_seconds tai /metrics."
  exit 1
fi

if ! echo "$METRICS" | grep -q "active_requests"; then
  echo "Chua tim thay custom metric Gauge: active_requests tai /metrics."
  exit 1
fi

echo "Buoc 2 da hoan thanh thanh cong!"
exit 0
