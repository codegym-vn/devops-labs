#!/bin/bash

# Kiem tra Nginx dang phan hoi
if ! curl -s http://localhost 2>/dev/null | grep -q "Backend"; then
    echo "[ERROR] curl http://localhost khong nhan duoc phan hoi tu backend. Hay kiem tra Nginx da duoc khoi dong va cau hinh dung."
    exit 1
fi

# Kiem tra keepalive trong upstream block
KEEPALIVE_CHECK=false
if grep -A12 "upstream" /etc/nginx/conf.d/*.conf 2>/dev/null | grep -qE "keepalive\s+[0-9]+"; then
    KEEPALIVE_CHECK=true
fi

# Kiem tra proxy_http_version 1.1
HTTP_VERSION_CHECK=false
if grep -rqE "proxy_http_version\s+1\.1" /etc/nginx/conf.d/ 2>/dev/null; then
    HTTP_VERSION_CHECK=true
fi

# Kiem tra proxy_set_header Connection ""
CONN_HEADER_CHECK=false
if grep -rqE 'proxy_set_header\s+Connection\s+""' /etc/nginx/conf.d/ 2>/dev/null; then
    CONN_HEADER_CHECK=true
fi

if [ "$KEEPALIVE_CHECK" = true ] && [ "$HTTP_VERSION_CHECK" = true ] && [ "$CONN_HEADER_CHECK" = true ]; then
    echo "[SUCCESS] Connection Pooling da duoc cau hinh day du va chinh xac! keepalive, proxy_http_version 1.1 va xoa Connection header deu da co mat."
    exit 0
elif [ "$KEEPALIVE_CHECK" = false ]; then
    echo "[ERROR] Chua tim thay chi thi 'keepalive' trong upstream block. Hay them 'keepalive 32;' vao block upstream."
    exit 1
elif [ "$HTTP_VERSION_CHECK" = false ]; then
    echo "[ERROR] Chua cau hinh 'proxy_http_version 1.1;'. Day la yeu cau bat buoc de tai su dung ket noi voi backend."
    exit 1
else
    echo '[ERROR] Chua cau hinh proxy_set_header Connection ""; trong location block de xoa co dong ket noi tu client.'
    exit 1
fi
