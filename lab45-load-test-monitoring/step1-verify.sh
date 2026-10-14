#!/bin/bash

# 1. Kiem tra target API
if ! curl -s http://localhost:8080/health | grep -q "UP"; then
  echo "[FAIL] Target API khong phan hoi tai port 8080"
  exit 1
fi

# 2. Kiem tra endpoint /metrics
if ! curl -s http://localhost:8080/metrics | grep -q "http_requests_total"; then
  echo "[FAIL] Endpoint /metrics cua Target API chua phoi bay dung Prometheus metrics"
  exit 1
fi

# 3. Kiem tra Prometheus Server
if ! curl -s http://localhost:9090/api/v1/targets | grep -q '"health":"up"'; then
  echo "[FAIL] Prometheus target chua o trang thai UP"
  exit 1
fi

# 4. Kiem tra Grafana
if ! curl -s http://localhost:3000/api/health | grep -q "ok"; then
  echo "[FAIL] Grafana Server khong phan hoi tai port 3000"
  exit 1
fi

echo "[OK] Ha tang Observability (Target API, Prometheus, Grafana) da san sang"
exit 0
