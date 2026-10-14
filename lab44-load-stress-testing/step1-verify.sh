#!/bin/bash

# Kiem tra tep script ton tai
if [ ! -f /root/load-test-lab/scripts/load-baseline.js ]; then
  echo "[FAIL] Khong tim thay tep /root/load-test-lab/scripts/load-baseline.js"
  exit 1
fi

# Kiem tra noi dung co khai bao vus va duration
if ! grep -q "vus:" /root/load-test-lab/scripts/load-baseline.js || ! grep -q "duration:" /root/load-test-lab/scripts/load-baseline.js; then
  echo "[FAIL] Kich ban chua khai bao options vus va duration hop le"
  exit 1
fi

# Kiem tra target server dang hoat dong
if ! curl -s http://localhost:8080/health | grep -q "UP"; then
  echo "[FAIL] Target API tai port 8080 khong phan hoi"
  exit 1
fi

# Kiem tra thuc thi k6 thanh cong
if ! k6 run --vus 1 --duration 2s /root/load-test-lab/scripts/load-baseline.js >/dev/null 2>&1; then
  echo "[FAIL] Kich ban k6 chay bao loi cu phap hoac khong ket noi duoc toi server"
  exit 1
fi

echo "[OK] Kich ban Baseline hop le va da vuot qua kiem tra Smoke Test"
exit 0
