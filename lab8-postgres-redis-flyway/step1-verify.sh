#!/bin/bash

ENV_FILE="/root/app/.env"

# 1. Kiem tra file .env ton tai va co du bien
if [ ! -f "$ENV_FILE" ]; then
    echo "[ERROR] File /root/app/.env chua ton tai. Hay tao file cau hinh bien moi truong."
    exit 1
fi

if ! grep -q "DATABASE_URL" "$ENV_FILE" || ! grep -q "REDIS_URL" "$ENV_FILE"; then
    echo "[ERROR] File .env thieu bien DATABASE_URL hoac REDIS_URL."
    exit 1
fi

if ! grep -q "DB_POOL_MIN" "$ENV_FILE" || ! grep -q "DB_POOL_MAX" "$ENV_FILE"; then
    echo "[ERROR] File .env thieu cac thiet lap Connection Pooling (DB_POOL_MIN, DB_POOL_MAX)."
    exit 1
fi

# 2. Kiem tra ket noi PostgreSQL voi user store_admin
if ! docker exec -i postgres psql -U store_admin -d ecommerce_db -c "SELECT current_user;" 2>/dev/null | grep -qw "store_admin"; then
    echo "[ERROR] Khong the ket noi vao PostgreSQL bang user 'store_admin'. Hay kiem tra da tao user va cap quyen chua."
    exit 1
fi

# 3. Kiem tra key trong Redis co TTL hop le
TTL=$(docker exec -i redis redis-cli TTL session:token:xyz 2>/dev/null | tr -d '[:space:]')

if [ -z "$TTL" ] || [ "$TTL" -le 0 ]; then
    echo "[ERROR] Key 'session:token:xyz' khong ton tai trong Redis hoac da het han TTL (gia tri TTL: $TTL)."
    exit 1
fi

echo "[SUCCESS] Cau hinh ket noi an toan qua bien moi truong, thiet lap Connection Pool va TTL Redis deu hoat dong chinh xac!"
echo "Ket noi PostgreSQL bang store_admin: OK | Redis session TTL con lai: ${TTL}s"
exit 0
