#!/bin/bash

# Kiem tra UFW active va co rules cho SSH 2222 va HTTP 80
UFW_ACTIVE=false
SSH_RULE=false
HTTP_RULE=false

# Kiem tra UFW active
if ufw status 2>/dev/null | grep -qi "Status: active"; then
    UFW_ACTIVE=true
fi

# Kiem tra rule cho port 2222
if ufw status 2>/dev/null | grep -qE "2222/tcp.*(ALLOW|LIMIT)"; then
    SSH_RULE=true
fi

# Kiem tra rule cho port 80
if ufw status 2>/dev/null | grep -qE "80/tcp.*ALLOW"; then
    HTTP_RULE=true
fi

if [ "$UFW_ACTIVE" = true ] && [ "$SSH_RULE" = true ] && [ "$HTTP_RULE" = true ]; then
    echo "[SUCCESS] Tuong lua UFW da duoc cau hinh dung: Active, SSH 2222 cho phep, HTTP 80 cho phep."
    exit 0
elif [ "$UFW_ACTIVE" = false ]; then
    echo "[ERROR] UFW chua duoc kich hoat. Hay chay 'ufw --force enable' de bat tuong lua."
    exit 1
elif [ "$SSH_RULE" = false ]; then
    echo "[ERROR] Chua co rule cho phep SSH tren port 2222. Hay chay 'ufw allow 2222/tcp' hoac 'ufw limit 2222/tcp'."
    exit 1
else
    echo "[ERROR] Chua co rule cho phep HTTP tren port 80. Hay chay 'ufw allow 80/tcp'."
    exit 1
fi
