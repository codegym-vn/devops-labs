#!/bin/bash
# step3-verify.sh — Lab 15: Kiem tra Multi-tier Architecture & Network Isolation

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ] || ([ "$3" = "nonempty" ] && [ -n "$2" ]); then
    echo "   $1"; PASS=$((PASS+1))
  else
    echo "   $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 3: Kiểm Tra Kết Nối Đa Tầng Liên Container & Cô Lập Mạng ==="
echo ""

# 1. Kiem tra volume redis_data ton tai
VOL_REDIS=$(docker volume inspect redis_data >/dev/null 2>&1 && echo "ok" || echo "")
check "Named Volume 'redis_data' đã được tạo" \
  "$VOL_REDIS" "ok" \
  "Chạy lệnh: docker volume create redis_data"

# 2. Kiem tra container redis-db dang chay tren app-net
REDIS_RUNNING=$(docker inspect -f '{{.State.Running}}' redis-db 2>/dev/null)
REDIS_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "app-net"}}ok{{end}}{{end}}' redis-db 2>/dev/null)
REDIS_MOUNT=$(docker inspect -f '{{range .Mounts}}{{if eq .Name "redis_data"}}{{.Destination}}{{end}}{{end}}' redis-db 2>/dev/null)

check "Container 'redis-db' đang chạy trên mạng 'app-net' với volume 'redis_data'" \
  "$([ "$REDIS_RUNNING" = "true" ] && [ "$REDIS_NET" = "ok" ] && [ "$REDIS_MOUNT" = "/data" ] && echo "ok" || echo "")" "ok" \
  "Chạy lệnh ở mục 3.2 để khởi động container redis-db"

# 3. Kiem tra container web-client dang chay tren app-net
WEB_RUNNING=$(docker inspect -f '{{.State.Running}}' web-client 2>/dev/null)
WEB_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "app-net"}}ok{{end}}{{end}}' web-client 2>/dev/null)
check "Container 'web-client' đang chạy và kết nối mạng 'app-net'" \
  "$([ "$WEB_RUNNING" = "true" ] && [ "$WEB_NET" = "ok" ] && echo "ok" || echo "")" "ok" \
  "Chạy lệnh ở mục 3.3 để khởi động container web-client"

# 4. Kiem tra du lieu Redis qua mang
REDIS_VALUE=$(docker exec redis-db redis-cli get learner_role 2>/dev/null | tr -d '\r\n')
check "Dữ liệu key 'learner_role' trong Redis lưu chính xác 'DevOps Engineer'" \
  "$REDIS_VALUE" "DevOps Engineer" \
  "Thực hiện lệnh: docker exec web-client redis-cli -h redis-db SET learner_role 'DevOps Engineer'"

# 5. Kiem tra container isolated-box ton tai
ISOLATED_EXISTS=$(docker inspect -f '{{.State.Running}}' isolated-box 2>/dev/null)
check "Container 'isolated-box' đã được tạo để kiểm thử cô lập mạng" \
  "$ISOLATED_EXISTS" "true" \
  "Chạy lệnh ở mục 3.5 để tạo container isolated-box"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " [SUCCESS] Chúc mừng! Bạn đã hoàn thành toàn bộ Lab 15 về Docker Volume & Custom Bridge Network!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
