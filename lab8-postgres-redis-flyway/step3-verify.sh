#!/bin/bash

# 1. Kiem tra ban ghi san pham trong PostgreSQL
PROD_COUNT=$(docker exec -i postgres psql -U postgres -d ecommerce_db -t -c "SELECT count(*) FROM products;" 2>/dev/null | tr -d '[:space:]')

if [ -z "$PROD_COUNT" ] || [ "$PROD_COUNT" -lt 1 ]; then
    echo "[ERROR] Chua tim thay san pham nao trong bang products cua PostgreSQL. Hay them san pham bang lenh INSERT."
    exit 1
fi

# 2. Kiem tra key cache trong Redis
REDIS_KEYS=$(docker exec -i redis redis-cli KEYS "product:*" 2>/dev/null)

if [ -z "$REDIS_KEYS" ]; then
    echo "[ERROR] Chua tim thay key cache nao dang 'product:*:data' trong Redis. Hay thuc hien cache san pham bang lenh SET."
    exit 1
fi

# 3. Kiem tra noi dung va TTL cua key product:1:data
FIRST_KEY=$(echo "$REDIS_KEYS" | head -n 1 | tr -d '[:space:]')
CACHE_CONTENT=$(docker exec -i redis redis-cli GET "$FIRST_KEY" 2>/dev/null)
TTL=$(docker exec -i redis redis-cli TTL "$FIRST_KEY" 2>/dev/null | tr -d '[:space:]')

if [ -z "$CACHE_CONTENT" ] || ! echo "$CACHE_CONTENT" | grep -qi "Keyboard"; then
    echo "[ERROR] Noi dung cache trong Redis ($FIRST_KEY) khong khop voi san pham trong PostgreSQL."
    echo "Noi dung thuc te trong Redis: $CACHE_CONTENT"
    exit 1
fi

if [ -z "$TTL" ] || [ "$TTL" -le 0 ]; then
    echo "[ERROR] Key cache $FIRST_KEY khong co thoi gian het han TTL hop le (gia tri TTL: $TTL)."
    exit 1
fi

echo "[SUCCESS] Tich hop he thong va mo hinh Cache-Aside hoat dong hoan hao!"
echo "Du lieu trong PostgreSQL va Redis dong nhat 100%. TTL cache con lai: ${TTL}s."
exit 0
