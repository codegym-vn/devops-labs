#!/bin/bash

# Kiem tra co cau hinh weight cho backend 8003 khong
WEIGHT_CONF=false
if grep -E "127\.0\.0\.1:8003.*weight=[2-9]" /etc/nginx/conf.d/*.conf 2>/dev/null; then
    WEIGHT_CONF=true
fi

# Gui 15 request va thong ke so luong phan hoi
RESULTS=$(for i in $(seq 1 15); do curl -s http://localhost 2>/dev/null; done)

COUNT_8003=$(echo "$RESULTS" | grep -c "Backend 8003")
UNIQUE_BACKENDS=$(echo "$RESULTS" | grep "Backend" | sort -u | wc -l)

if [ "$WEIGHT_CONF" = true ] && [ "$COUNT_8003" -ge 7 ] && [ "$UNIQUE_BACKENDS" -ge 2 ]; then
    echo "[SUCCESS] Weighted Load Balancing hoat dong dung! Backend 8003 nhan $COUNT_8003/15 requests (khoang 60%) va traffic van duoc phan phoi toi ca $UNIQUE_BACKENDS backend."
    exit 0
elif [ "$WEIGHT_CONF" = false ]; then
    echo "[ERROR] Chua tim thay cau hinh weight cho backend 8003 trong file /etc/nginx/conf.d/. Hay dat weight=3 cho 127.0.0.1:8003."
    exit 1
elif [ "$UNIQUE_BACKENDS" -lt 2 ]; then
    echo "[ERROR] Chi co 1 backend phan hoi. Hay kiem tra upstream block co day du ca 3 backend server hay khong."
    exit 1
else
    echo "[ERROR] Backend 8003 chi nhan $COUNT_8003/15 requests (yeu cau toi thieu 7/15). Hay kiem tra lai cau hinh va reload Nginx."
    exit 1
fi
