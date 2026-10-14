#!/bin/bash

# 1. Kiem tra Nginx Reverse Proxy
if ! curl -s http://localhost:80/api/data | grep -q '"status": "OK"'; then
  echo "[FAIL] Nginx Reverse Proxy tai port 80 khong phan hoi"
  exit 1
fi

# 2. Kiem tra Backend Service
if ! curl -s http://127.0.0.1:8080/health | grep -q "UP"; then
  echo "[FAIL] Backend Service tai port 8080 khong phan hoi"
  exit 1
fi

# 3. Kiem tra tep cau hinh nginx.conf
if [ ! -f /root/infra-opt-lab/nginx/nginx.conf ]; then
  echo "[FAIL] Khong tim thay tep cau hinh /root/infra-opt-lab/nginx/nginx.conf"
  exit 1
fi

echo "[OK] Da khao sat thanh cong Nginx va cac thong so mang ban dau"
exit 0
