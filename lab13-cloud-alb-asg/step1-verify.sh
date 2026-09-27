#!/bin/bash
# step1-verify.sh — Lab 13: Kiểm tra Instances + Network

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

echo "=== Bước 1: Instances + Network ==="
echo ""

# 1. Network app-network tồn tại
APP_NET=$(docker network inspect app-network \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
check "Network 'app-network' (10.1.0.0/24) đã tạo" \
  "$(echo $APP_NET | grep -c '10.1.0')" "1" \
  "Chạy: docker network create --subnet 10.1.0.0/24 app-network"

# 2. app-1 đang chạy
APP1=$(docker inspect app-1 --format '{{.State.Status}}' 2>/dev/null)
check "Container 'app-1' đang running" "$APP1" "running" \
  "Chạy lại phần 1.3 để start_instance 1"

# 3. app-2 đang chạy
APP2=$(docker inspect app-2 --format '{{.State.Status}}' 2>/dev/null)
check "Container 'app-2' đang running" "$APP2" "running" \
  "Chạy lại phần 1.3 để start_instance 2"

# 4. Cả 2 container có label asg=web-asg
ASG_COUNT=$(docker ps --filter "label=asg=web-asg" -q | wc -l)
check "Ít nhất 2 instances có label asg=web-asg (desired=2)" \
  "$([ $ASG_COUNT -ge 2 ] && echo ok)" "ok" \
  "Thêm --label asg=web-asg vào lệnh docker run"

# 5. Port 8081 phản hồi
HTTP1=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/server-id 2>/dev/null)
check "app-1 phản hồi HTTP 200 tại port 8081" "$HTTP1" "200" \
  "Kiểm tra docker ps | grep app-1"

# 6. Port 8082 phản hồi
HTTP2=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/server-id 2>/dev/null)
check "app-2 phản hồi HTTP 200 tại port 8082" "$HTTP2" "200" \
  "Kiểm tra docker ps | grep app-2"

# 7. server-id endpoint trả về đúng tên
SRV1=$(curl -s http://localhost:8081/server-id 2>/dev/null | grep -i "app-1")
check "app-1 trả về server-id chứa 'app-1'" \
  "$([ -n "$SRV1" ] && echo ok)" "ok" \
  "Đảm bảo script tạo /usr/share/nginx/html/server-id chứa 'app-1'"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Instances sẵn sàng!" && exit 0 || exit 1

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

APP3=$(docker inspect app-3 --format '{{.State.Status}}' 2>/dev/null)
check "[Bài tập] Container 'app-3' đang running" "$APP3" "running" \
  "start_instance 3 hoặc docker run -d --name app-3 --network app-network --ip 10.1.0.13 -p 8083:80 ..."

APP3_IP=$(docker inspect app-3 --format '{{.NetworkSettings.Networks.app-network.IPAddress}}' 2>/dev/null)
check "[Bài tập] app-3 có IP 10.1.0.13" "$APP3_IP" "10.1.0.13" \
  "Thêm --ip 10.1.0.13 vào lệnh docker run"

APP3_ASG=$(docker inspect app-3 --format '{{index .Config.Labels "asg"}}' 2>/dev/null)
check "[Bài tập] app-3 có label asg=web-asg" "$APP3_ASG" "web-asg" \
  "Thêm --label asg=web-asg"

APP3_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/server-id 2>/dev/null)
check "[Bài tập] app-3 phản hồi HTTP 200 tại port 8083" "$APP3_HTTP" "200" \
  "Kiểm tra port mapping -p 8083:80"
