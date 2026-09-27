#!/bin/bash
# step3-verify.sh — Kiểm tra round-robin + health check + benchmark
source /tmp/lab-env.sh 2>/dev/null || true
PASS=0; FAIL=0

check() {
  [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } \
                  || { echo "  ❌ $1 (nhận: '$2', cần: '$3')"; FAIL=$((FAIL+1)); }
}
check_range() {
  local desc="$1" val="$2" lo="$3" hi="$4"
  if [ "$val" -ge "$lo" ] && [ "$val" -le "$hi" ] 2>/dev/null; then
    echo "  ✅ $desc ($val trong khoảng $lo–$hi)"
    PASS=$((PASS+1))
  else
    echo "  ❌ $desc ($val nằm ngoài khoảng $lo–$hi)"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Kiểm tra Bước 3: Phân tải và Health Check ==="
echo ""

# Cả hai container đang chạy
for i in 1 2; do
  STATUS=$(docker inspect "app-${i}" --format '{{.State.Status}}' 2>/dev/null)
  check "Container app-${i} đang chạy" "$STATUS" "running"
done

# Health endpoints đều healthy
for PORT in 8081 8082; do
  HC=$(curl -s http://localhost:${PORT}/health 2>/dev/null | tr -d '\n')
  check "Backend port ${PORT} trả về 'healthy'" "$HC" "healthy"
done

# Nginx phân tải đúng: đếm tỷ lệ phân phối 20 request
declare -A CNT
for i in $(seq 1 20); do
  SRV=$(curl -s http://localhost/server-id 2>/dev/null | grep -oP 'app-\d+')
  CNT[$SRV]=$((${CNT[$SRV]:-0} + 1))
done
APP1=${CNT[app-1]:-0}
APP2=${CNT[app-2]:-0}
echo ""
echo "  Phân phối 20 requests: app-1=$APP1, app-2=$APP2"
check_range "app-1 nhận 30–70% traffic" "$APP1" 6 14
check_range "app-2 nhận 30–70% traffic" "$APP2" 6 14

# Header X-Served-By xuất hiện trong response
HEADER=$(curl -sI http://localhost/ 2>/dev/null | grep -ci "x-served-by")
check "Nginx thêm header X-Served-By vào response" "$HEADER" "1"

# Nginx config có max_fails (passive health check)
HAS_MAXFAIL=$(grep -c "max_fails" /etc/nginx/conf.d/alb.conf 2>/dev/null || echo "0")
check "Nginx upstream cấu hình max_fails (passive health check)" "$HAS_MAXFAIL" "2"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 Load Balancer hoạt động đúng! Tiếp tục Bước 4."; exit 0; } \
               || { echo "⚠️  $FAIL lỗi cần sửa."; exit 1; }
