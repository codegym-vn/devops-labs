#!/bin/bash

# Kiem tra SSH dang listen tren port 2222
PORT_CHECK=false
if ss -tlpn 2>/dev/null | grep -q ':2222\b'; then
    PORT_CHECK=true
fi

# Kiem tra PasswordAuthentication no trong cau hinh
PASS_CHECK=false
if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
    PASS_CHECK=true
fi

if [ "$PORT_CHECK" = true ] && [ "$PASS_CHECK" = true ]; then
    echo "[SUCCESS] SSH da duoc gia co: Port 2222, PasswordAuthentication no. Brute-force attack khong con hieu qua!"
    exit 0
elif [ "$PORT_CHECK" = false ]; then
    echo "[ERROR] SSH chua listen tren port 2222. Hay kiem tra file cau hinh va restart SSH daemon."
    exit 1
else
    echo "[ERROR] PasswordAuthentication chua duoc dat thanh 'no'. Hay kiem tra lai file hardening.conf."
    exit 1
fi
