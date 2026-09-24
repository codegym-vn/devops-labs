#!/bin/bash

# 1. Kiem tra so luong migration thanh cong trong flyway_schema_history
SUCCESS_COUNT=$(docker exec -i postgres psql -U postgres -d ecommerce_db -t -c "SELECT count(*) FROM flyway_schema_history WHERE success = true;" 2>/dev/null | tr -d '[:space:]')

if [ -z "$SUCCESS_COUNT" ] || [ "$SUCCESS_COUNT" -lt 2 ]; then
    echo "[ERROR] Chua co du 2 migration thanh cong trong flyway_schema_history (hien tai: $SUCCESS_COUNT). Hay tao file V2 va chay 'flyway migrate'."
    exit 1
fi

# 2. Kiem tra su ton tai cua bang products va orders
TABLE_COUNT=$(docker exec -i postgres psql -U postgres -d ecommerce_db -t -c "SELECT count(*) FROM information_schema.tables WHERE table_name IN ('products', 'orders');" 2>/dev/null | tr -d '[:space:]')

if [ "$TABLE_COUNT" -ne 2 ]; then
    echo "[ERROR] Chua tim thay day du 2 bang 'products' va 'orders' trong PostgreSQL."
    exit 1
fi

# 3. Kiem tra tinh toan ven rang buoc khoa ngoai (Foreign Key Integrity Check)
FK_TEST_OUTPUT=$(docker exec -i postgres psql -U postgres -d ecommerce_db -c "INSERT INTO orders (user_id, total_amount) VALUES (99999, 50.0);" 2>&1)

if ! echo "$FK_TEST_OUTPUT" | grep -qi "foreign key"; then
    echo "[ERROR] Rang buoc khoa ngoai giua bang orders va users chua hoat dong chinh xac."
    echo "Phan hoi tu PostgreSQL: $FK_TEST_OUTPUT"
    exit 1
fi

echo "[SUCCESS] Flyway migration va kiem tra tinh toan ven CSDL thanh cong!"
echo "Da ghi nhan $SUCCESS_COUNT ban migration hop le. Rang buoc khoa ngoai da ngan chan thanh cong du lieu vi pham toan ven."
exit 0
