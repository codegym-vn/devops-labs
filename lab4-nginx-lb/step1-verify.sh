#!/bin/bash

# Kiem tra curl qua Nginx tra ve noi dung tu Backend 8002
PROXY_CHECK=false
if curl -s http://localhost 2>/dev/null | grep -q "Backend 8002"; then
    PROXY_CHECK=true
fi

# Kiem tra co proxy_set_header X-Real-IP trong cau hinh
HEADER_CHECK=false
if grep -rq "proxy_set_header.*X-Real-IP" /etc/nginx/conf.d/ 2>/dev/null; then
    HEADER_CHECK=true
fi

if [ "$PROXY_CHECK" = true ] && [ "$HEADER_CHECK" = true ]; then
    echo "[SUCCESS] Nginx Reverse Proxy hoat dong dung! Request duoc chuyen tiep toi Backend 8002 va IP client duoc bao toan qua X-Real-IP."
    exit 0
elif [ "$PROXY_CHECK" = false ]; then
    echo "[ERROR] curl http://localhost khong tra ve noi dung tu Backend 8002. Hay kiem tra proxy_pass da chuyen sang port 8002 va dam bao Nginx da reload."
    exit 1
else
    echo "[ERROR] Chua cau hinh proxy_set_header X-Real-IP. Hay them dong nay vao block location trong cau hinh Nginx."
    exit 1
fi
