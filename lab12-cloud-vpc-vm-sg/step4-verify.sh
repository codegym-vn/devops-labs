#!/bin/bash
# step4-verify.sh — Lab 12: Kiểm tra Cleanup

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ]; then
    echo "   $1"; PASS=$((PASS+1))
  else
    echo "   $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 4: Cleanup ==="
echo ""

# 1. Không còn container web-server-1
WEB_EXISTS=$(docker ps -a --filter "name=web-server-1" -q | wc -l)
check "Container 'web-server-1' đã xóa" "$WEB_EXISTS" "0" \
  "Chạy: docker stop web-server-1 && docker rm web-server-1"

# 2. Không còn container db-server-1
DB_EXISTS=$(docker ps -a --filter "name=db-server-1" -q | wc -l)
check "Container 'db-server-1' đã xóa" "$DB_EXISTS" "0" \
  "Chạy: docker stop db-server-1 && docker rm db-server-1"

# 3. Network public-subnet đã xóa
PUB_EXISTS=$(docker network ls --filter "name=public-subnet" -q | wc -l)
check "Network 'public-subnet' đã xóa" "$PUB_EXISTS" "0" \
  "Chạy: docker network rm public-subnet"

# 4. Network private-subnet đã xóa
PRIV_EXISTS=$(docker network ls --filter "name=private-subnet" -q | wc -l)
check "Network 'private-subnet' đã xóa" "$PRIV_EXISTS" "0" \
  "Chạy: docker network rm private-subnet"

# 5. UFW đã disable hoặc rules đã clean
UFW_LAB_RULES=$(ufw status 2>/dev/null | grep -c "8081\|8080.*ALLOW" || echo 0)
check "UFW rules lab đã được xóa" "$UFW_LAB_RULES" "0" \
  "Chạy: ufw delete allow 8081/tcp | ufw delete allow 8080/tcp"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
if [ $FAIL -eq 0 ]; then
  echo " Dọn dẹp hoàn tất! Không còn tài nguyên nào."
  echo "   → Thói quen tốt: luôn cleanup sau lab để tránh lãng phí tài nguyên."
  exit 0
else
  exit 1
fi

echo ""
echo "===  Bài tập ==="
echo ""

# Challenge: /tmp/infra-snapshot.json
check "[Bài tập] File /tmp/infra-snapshot.json đã tạo" \
  "$(test -f /tmp/infra-snapshot.json && echo ok)" "ok" \
  "Tạo file JSON với python3 hoặc echo/printf"

JSON_VALID=$(python3 -c "import json; json.load(open('/tmp/infra-snapshot.json'))" 2>/dev/null && echo ok)
check "[Bài tập] /tmp/infra-snapshot.json là JSON hợp lệ" "$JSON_VALID" "ok" \
  "Kiểm tra: python3 -m json.tool /tmp/infra-snapshot.json"

HAS_STATUS=$(python3 -c "
import json
d = json.load(open('/tmp/infra-snapshot.json'))
print('ok' if d.get('status') == 'cleaned' else '')
" 2>/dev/null)
check "[Bài tập] JSON có field 'status': 'cleaned'" "$HAS_STATUS" "ok" \
  "Thêm 'status': 'cleaned' vào JSON"

HAS_TIMESTAMP=$(python3 -c "
import json
d = json.load(open('/tmp/infra-snapshot.json'))
print('ok' if d.get('timestamp') else '')
" 2>/dev/null)
check "[Bài tập] JSON có field 'timestamp'" "$HAS_TIMESTAMP" "ok" \
  "Dùng: \$(date -u +\"%Y-%m-%dT%H:%M:%SZ\") để lấy thời gian"
