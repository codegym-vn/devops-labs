#!/bin/bash
# step2-verify.sh — Lab 13: Kiểm tra Load Balancer + Health Check

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

echo "=== Bước 2: Load Balancer + Health Check ==="
echo ""

# 1. File config LB tồn tại
check "Nginx LB config /etc/nginx/conf.d/lb.conf đã tạo" \
  "$(test -f /etc/nginx/conf.d/lb.conf && echo ok)" "ok" \
  "Chạy phần 2.1 để tạo /etc/nginx/conf.d/lb.conf"

# 2. Config chứa upstream backend
UPSTREAM=$(grep -c "upstream backend" /etc/nginx/conf.d/lb.conf 2>/dev/null)
check "Config có 'upstream backend' block" \
  "$([ $UPSTREAM -ge 1 ] && echo ok)" "ok" \
  "Đảm bảo file lb.conf có block 'upstream backend { ... }'"

# 3. Config dùng least_conn
LEASTCONN=$(grep -c "least_conn" /etc/nginx/conf.d/lb.conf 2>/dev/null)
check "Load Balancer dùng thuật toán least_conn" \
  "$([ $LEASTCONN -ge 1 ] && echo ok)" "ok" \
  "Thêm 'least_conn;' vào upstream block"

# 4. max_fails được cấu hình (passive health check)
MAX_FAILS=$(grep -c "max_fails" /etc/nginx/conf.d/lb.conf 2>/dev/null)
check "Passive health check (max_fails) đã cấu hình" \
  "$([ $MAX_FAILS -ge 1 ] && echo ok)" "ok" \
  "Thêm 'max_fails=3 fail_timeout=10s' vào từng server trong upstream"

# 5. Nginx đang chạy với config mới
NGINX_OK=$(nginx -t 2>&1 | grep -c "ok")
check "Nginx config hợp lệ (nginx -t)" \
  "$([ $NGINX_OK -ge 1 ] && echo ok)" "ok" \
  "Chạy: nginx -t để xem lỗi"

# 6. LB phản hồi tại port 80
LB_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/lb-health 2>/dev/null)
check "Load Balancer phản hồi HTTP 200 tại port 80" "$LB_HTTP" "200" \
  "Kiểm tra: systemctl status nginx | nginx -s reload"

# 7. LB phân phối đến đúng backend (kiểm tra header X-Served-By)
SERVED_BY=$(curl -s -I http://localhost/server-id 2>/dev/null \
  | grep -i "x-served-by" | head -1)
check "Header X-Served-By có trong response (proxy hoạt động)" \
  "$([ -n "$SERVED_BY" ] && echo ok)" "ok" \
  "Đảm bảo config có: add_header X-Served-By \$upstream_addr always;"

# 8. Health script tồn tại và chạy được
check "Script /tmp/health-monitor.sh đã tạo" \
  "$(test -x /tmp/health-monitor.sh && echo ok)" "ok" \
  "Chạy phần 2.3 để tạo health-monitor.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Load Balancer hoạt động đúng!" && exit 0 || exit 1

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

METRICS_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/metrics 2>/dev/null)
check "[Bài tập] Endpoint /metrics trả về HTTP 200" "$METRICS_HTTP" "200" \
  "Thêm: location /metrics { return 200 'upstream: backend\nalgorithm: least_conn\n...'; } vào lb.conf"

METRICS_BODY=$(curl -s http://localhost/metrics 2>/dev/null)
check "[Bài tập] /metrics có chứa 'upstream' hoặc 'algorithm'" \
  "$(echo $METRICS_BODY | grep -ic 'upstream\|algorithm')" "1" \
  "Response phải chứa thông tin về upstream backend"
