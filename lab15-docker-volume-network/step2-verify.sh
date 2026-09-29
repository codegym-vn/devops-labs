#!/bin/bash
# step2-verify.sh — Lab 15: Kiem tra Custom Bridge Network va Embedded DNS

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

echo "=== Bước 2: Kiểm Tra Custom Bridge Network & Phân Giải Tên Miền Embedded DNS ==="
echo ""

# 1. Kiem tra network app-net ton tai va co driver bridge
NET_DRIVER=$(docker network inspect -f '{{.Driver}}' app-net 2>/dev/null)
check "Custom Network 'app-net' tồn tại với driver 'bridge'" \
  "$NET_DRIVER" "bridge" \
  "Chạy lệnh: docker network create --driver bridge --subnet 172.28.0.0/16 app-net"

# 2. Kiem tra dải Subnet 172.28.0.0/16
NET_SUBNET=$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' app-net 2>/dev/null)
check "Network 'app-net' được quy hoạch đúng Subnet '172.28.0.0/16'" \
  "$NET_SUBNET" "172.28.0.0/16" \
  "Đảm bảo cờ: --subnet 172.28.0.0/16 khi tạo mạng app-net"

# 3. Kiem tra container service-alpha ket noi vao app-net
ALPHA_RUNNING=$(docker inspect -f '{{.State.Running}}' service-alpha 2>/dev/null)
ALPHA_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "app-net"}}ok{{end}}{{end}}' service-alpha 2>/dev/null)
check "Container 'service-alpha' đang chạy và kết nối mạng 'app-net'" \
  "$([ "$ALPHA_RUNNING" = "true" ] && [ "$ALPHA_NET" = "ok" ] && echo "ok" || echo "")" "ok" \
  "Chạy lệnh: docker run -d --name service-alpha --network app-net alpine:3.19 sleep 3600"

# 4. Kiem tra container service-beta ket noi vao app-net
BETA_RUNNING=$(docker inspect -f '{{.State.Running}}' service-beta 2>/dev/null)
BETA_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{if eq $k "app-net"}}ok{{end}}{{end}}' service-beta 2>/dev/null)
check "Container 'service-beta' đang chạy và kết nối mạng 'app-net'" \
  "$([ "$BETA_RUNNING" = "true" ] && [ "$BETA_NET" = "ok" ] && echo "ok" || echo "")" "ok" \
  "Chạy lệnh: docker run -d --name service-beta --network app-net alpine:3.19 sleep 3600"

# 5. Kiem tra ping qua Embedded DNS tu service-beta sang service-alpha
PING_RESULT=$(docker exec service-beta ping -c 1 -W 2 service-alpha >/dev/null 2>&1 && echo "ok" || echo "")
check "Embedded DNS phân giải tên miền và kết nối thành công giữa hai container" \
  "$PING_RESULT" "ok" \
  "Thử chạy kiểm tra: docker exec service-beta ping -c 2 service-alpha"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " [SUCCESS] Xuất sắc! Custom Bridge Network và Embedded DNS hoạt động hoàn hảo!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
