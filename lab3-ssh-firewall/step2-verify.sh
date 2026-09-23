#!/bin/bash

# Kiem tra curl qua tunnel port 9090 tra ve HTTP 200
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 2>/dev/null | grep -q "200"; then
    echo "[SUCCESS] SSH Local Port Forwarding dang hoat dong! Traffic tu port 9090 da duoc chuyen tiep thanh cong qua tunnel toi port 8080."
    exit 0
else
    echo "[ERROR] Khong the truy cap http://localhost:9090. Hay dam bao: (1) mock service dang chay tren port 8080, (2) SSH tunnel da duoc tao tu port 9090 toi 8080."
    exit 1
fi
