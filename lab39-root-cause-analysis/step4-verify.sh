#!/bin/bash
set -e

ENV_FILE="/root/incident-lab/payment-service.env"
POST_MORTEM_FILE="/root/incident-report/post-mortem.md"

# 1. Kiem tra cau hinh DB_POOL_MAX da duoc tang chua
if [ ! -f "$ENV_FILE" ]; then
  echo "Loi: Khong tim thay tep cau hinh $ENV_FILE!"
  exit 1
fi

POOL_MAX=$(grep "DB_POOL_MAX=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' \r\n')
if [ -z "$POOL_MAX" ] || [ "$POOL_MAX" -lt 10 ]; then
  echo "Loi: DB_POOL_MAX trong $ENV_FILE hien tai la '$POOL_MAX'. Can tang len toi thieu 10 (khuyen nghi 20) de dap ung tai!"
  exit 1
fi

# 2. Kiem tra tien trinh payment-service dang chay
if ! pgrep -f "payment-service.js" > /dev/null; then
  echo "Loi: Payment Service chua duoc khoi dong lai! Hay chay /root/incident-lab/restart-payment-service.sh."
  exit 1
fi

# 3. Kiem tra bao cao Post-Mortem da duoc tao chua
if [ ! -f "$POST_MORTEM_FILE" ]; then
  echo "Loi: Chua tim thay bao cao Post-Mortem tai $POST_MORTEM_FILE!"
  echo "Goi y: Hay tao tep $POST_MORTEM_FILE voi noi dung phan tich 5 Whys va Action Items."
  exit 1
fi

if ! grep -qi "5 Whys" "$POST_MORTEM_FILE"; then
  echo "Loi: Bao cao Post-Mortem chua chua phan tich 5 Whys!"
  exit 1
fi

# 4. Ban test tai thuc te (Verification Load Test)
echo "Dang thuc hien kiem thu phuc hoi dich vu voi 5 request dong thoi..."
FAIL_COUNT=0
for i in {1..5}; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost/api/checkout \
    -H "Content-Type: application/json" \
    -d '{"item":"Verify Item","amount":999}' --max-time 4 || echo "000")

  if [ "$CODE" != "200" ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  -> Request $i that bai voi ma HTTP: $CODE"
  fi
done

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "Loi: Van con $FAIL_COUNT / 5 request that bai! He thong chua phuc hoi hoan toan."
  exit 1
fi

echo "[XAC THUC HOAN TAT] 100% request thanh cong (HTTP 200). Su co P1 da duoc giai cuu thanh cong va tai lieu hoa day du!"
exit 0
