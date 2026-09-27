#!/bin/bash
# step3-verify.sh — Lab 12: Kiểm tra Compute Instances

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ] || ([ "$3" = "nonempty" ] && [ -n "$2" ]); then
    echo "  ✅ $1"; PASS=$((PASS+1))
  else
    echo "  ❌ $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 3: Compute Instances ==="
echo ""

# 1. SSH key pair đã được tạo
check "SSH Key Pair /tmp/lab-keypair đã tạo" \
  "$(test -f /tmp/lab-keypair && echo ok)" "ok" \
  "Chạy: ssh-keygen -t ed25519 -f /tmp/lab-keypair -N \"\""

# 2. web-server-1 đang chạy
WEB1_STATUS=$(docker inspect web-server-1 \
  --format '{{.State.Status}}' 2>/dev/null)
check "Container 'web-server-1' đang running" "$WEB1_STATUS" "running" \
  "Chạy lại phần 3.2 trong hướng dẫn"

# 3. web-server-1 có label Role=web
WEB1_ROLE=$(docker inspect web-server-1 \
  --format '{{index .Config.Labels "Role"}}' 2>/dev/null)
check "web-server-1 có label Role=web" "$WEB1_ROLE" "web" \
  "Thêm --label Role=web vào lệnh docker run"

# 4. db-server-1 đang chạy trong private-subnet
DB1_SUBNET=$(docker inspect db-server-1 \
  --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null \
  | tr ',' '\n' | grep private-subnet | head -1)
check "db-server-1 chạy trong private-subnet" \
  "$(echo $DB1_SUBNET | grep -c private-subnet)" "1" \
  "Tạo db-server-1 với --network private-subnet"

# 5. HTTP trả về 200
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 2>/dev/null)
check "Web server phản hồi HTTP 200 tại port 8081" "$HTTP_CODE" "200" \
  "Kiểm tra docker ps | grep web-server-1 và đúng port mapping -p 8081:80"

# 6. Health endpoint hoạt động
HEALTH=$(curl -s http://localhost:8081/health 2>/dev/null | tr -d '\n')
check "Endpoint /health phản hồi 'healthy'" \
  "$(echo $HEALTH | grep -ic healthy)" "1" \
  "Đảm bảo nginx config có location /health { return 200 \"healthy\"; }"

# 7. DB không có port public (private subnet isolation)
DB_PORTS=$(docker inspect db-server-1 \
  --format '{{.HostConfig.PortBindings}}' 2>/dev/null)
check "db-server-1 không expose port ra ngoài Internet" \
  "$DB_PORTS" "map[]" \
  "Xóa -p flag khi tạo db-server-1"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Instances triển khai đúng!" && exit 0 || exit 1
