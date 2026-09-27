#!/bin/bash
# step3-verify.sh — Lab 13: Kiểm tra phân phối traffic

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

echo "=== Bước 3: Phân phối traffic + Health Check ==="
echo ""

# 1. LB đang phân phối đến nhiều backend
echo "  Đang gửi 20 request để kiểm tra phân phối..."
declare -A COUNT
for i in $(seq 1 20); do
  SRV=$(curl -s http://localhost/server-id 2>/dev/null | grep -oE 'app-[0-9]+' | head -1)
  [ -n "$SRV" ] && COUNT[$SRV]=$((${COUNT[$SRV]:-0}+1))
done

BACKENDS_HIT=$(echo ${!COUNT[@]} | wc -w)
check "LB phân phối đến ≥2 backend khác nhau (trong 20 request)" \
  "$([ $BACKENDS_HIT -ge 2 ] && echo ok)" "ok" \
  "Kiểm tra upstream config có đủ 2 server đang healthy"

# 2. app-1 nhận ít nhất 1 request
check "app-1 nhận ít nhất 1 request" \
  "$([ ${COUNT[app-1]:-0} -ge 1 ] && echo ok)" "ok" \
  "Kiểm tra app-1 đang chạy: docker ps | grep app-1"

# 3. app-2 nhận ít nhất 1 request
check "app-2 nhận ít nhất 1 request" \
  "$([ ${COUNT[app-2]:-0} -ge 1 ] && echo ok)" "ok" \
  "Kiểm tra app-2 đang chạy: docker ps | grep app-2"

echo "  Phân phối: $(for k in "${!COUNT[@]}"; do echo "$k:${COUNT[$k]}"; done | tr '\n' ' ')"

# 4. /health endpoint phản hồi healthy
HEALTH_RESP=$(curl -s http://localhost/health 2>/dev/null | grep -ic "healthy")
check "/health qua LB trả về 'healthy'" \
  "$([ $HEALTH_RESP -ge 1 ] && echo ok)" "ok" \
  "Kiểm tra nginx config có: location /health { proxy_pass http://backend/health; }"

# 5. File benchmark /tmp/bench-2.txt tồn tại (learner đã chạy wrk)
check "Benchmark baseline đã chạy (/tmp/bench-2.txt)" \
  "$(test -f /tmp/bench-2.txt && grep -q 'Requests' /tmp/bench-2.txt && echo ok)" "ok" \
  "Chạy: wrk -t2 -c20 -d15s http://localhost/server-id | tee /tmp/bench-2.txt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Load Balancer phân phối đúng!" && exit 0 || exit 1
