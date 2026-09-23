#!/bin/bash

# Kiem tra Nginx dang listen tren cong 443 va curl HTTPS thanh cong
LISTEN_CHECK=false
CURL_CHECK=false

if ss -tlpn 2>/dev/null | grep -E -q ':443\b'; then
    LISTEN_CHECK=true
fi

if curl -k -s -o /dev/null -w "%{http_code}" https://localhost 2>/dev/null | grep -q "200"; then
    CURL_CHECK=true
fi

if [ "$LISTEN_CHECK" = true ] && [ "$CURL_CHECK" = true ]; then
    echo "[SUCCESS] Nginx dang lang nghe tren cong 443 voi SSL va tra ve HTTP 200. HTTPS da duoc cau hinh thanh cong!"
    exit 0
elif [ "$LISTEN_CHECK" = true ] && [ "$CURL_CHECK" = false ]; then
    echo "[ERROR] Cong 443 dang mo nhung curl HTTPS khong tra ve status 200. Hay kiem tra lai cau hinh ssl_certificate va ssl_certificate_key trong Nginx."
    exit 1
else
    echo "[ERROR] Chua phat hien Nginx lang nghe tren cong 443. Hay dam bao da cau hinh 'listen 443 ssl' va chay 'systemctl start nginx'."
    exit 1
fi
