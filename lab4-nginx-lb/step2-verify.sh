#!/bin/bash

# Gui 10 request va kiem tra co it nhat 2 backend khac nhau trong response
RESULTS=$(for i in $(seq 1 10); do curl -s http://localhost 2>/dev/null; done)

UNIQUE_BACKENDS=$(echo "$RESULTS" | sort -u | wc -l)

if [ "$UNIQUE_BACKENDS" -ge 2 ]; then
    echo "[SUCCESS] Load Balancing hoat dong! Traffic duoc phan phoi toi $UNIQUE_BACKENDS backend khac nhau."
    exit 0
else
    echo "[ERROR] Chi phat hien $UNIQUE_BACKENDS backend. Load Balancing can phan phoi request toi it nhat 2 backend. Hay kiem tra upstream block trong cau hinh Nginx."
    exit 1
fi
