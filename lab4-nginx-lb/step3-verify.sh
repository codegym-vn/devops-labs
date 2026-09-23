#!/bin/bash

# Kiem tra keepalive trong upstream block
KEEPALIVE_CHECK=false
if grep -A5 "upstream" /etc/nginx/conf.d/proxy.conf 2>/dev/null | grep -q "keepalive"; then
    KEEPALIVE_CHECK=true
fi

# Kiem tra proxy_http_version 1.1
HTTP_VERSION_CHECK=false
if grep -q "proxy_http_version 1.1" /etc/nginx/conf.d/proxy.conf 2>/dev/null; then
    HTTP_VERSION_CHECK=true
fi

if [ "$KEEPALIVE_CHECK" = true ] && [ "$HTTP_VERSION_CHECK" = true ]; then
    echo "[SUCCESS] Connection Pooling da duoc cau hinh! keepalive va proxy_http_version 1.1 deu co mat. Nginx se tai su dung ket noi TCP toi backend."
    exit 0
elif [ "$KEEPALIVE_CHECK" = false ]; then
    echo "[ERROR] Chua tim thay chi thi 'keepalive' trong upstream block. Hay them 'keepalive 32' vao block upstream trong cau hinh Nginx."
    exit 1
else
    echo "[ERROR] Chua cau hinh 'proxy_http_version 1.1'. Day la bat buoc khi dung keepalive. Hay them vao block location."
    exit 1
fi
