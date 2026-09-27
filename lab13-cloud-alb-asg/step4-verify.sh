#!/bin/bash
# step4-verify.sh — Lab 13: Kiểm tra Scale-out + Cleanup

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

echo "=== Bước 4: Scale-out + Cleanup ==="
echo ""

# 1. Benchmark trước scale đã có
check "Benchmark baseline (trước scale) đã chạy" \
  "$(test -f /tmp/bench-before.txt && grep -q 'Requests' /tmp/bench-before.txt && echo ok)" "ok" \
  "Chạy: wrk -t2 -c50 -d20s http://localhost/server-id | tee /tmp/bench-before.txt"

# 2. Benchmark sau scale đã có
check "Benchmark sau scale-out đã chạy" \
  "$(test -f /tmp/bench-after.txt && grep -q 'Requests' /tmp/bench-after.txt && echo ok)" "ok" \
  "Chạy: wrk -t2 -c50 -d20s http://localhost/server-id | tee /tmp/bench-after.txt"

# 3. So sánh throughput (sau >= trước)
if [ -f /tmp/bench-before.txt ] && [ -f /tmp/bench-after.txt ]; then
  RPS_BEFORE=$(grep "Requests/sec" /tmp/bench-before.txt | awk '{print $2}' | sed 's/\..*//')
  RPS_AFTER=$(grep "Requests/sec" /tmp/bench-after.txt | awk '{print $2}' | sed 's/\..*//')
  echo "  Throughput: $RPS_BEFORE req/s → $RPS_AFTER req/s"
  check "Throughput sau scale-out ≥ trước scale" \
    "$([ ${RPS_AFTER:-0} -ge ${RPS_BEFORE:-0} ] && echo ok)" "ok" \
    "Scale-out nên tăng throughput — kiểm tra app-3 có trong upstream config"
fi

# 4. Auto-scale script đã tạo
check "Script /tmp/autoscale.sh đã tạo" \
  "$(test -x /tmp/autoscale.sh && echo ok)" "ok" \
  "Chạy phần 4.4 để tạo autoscale.sh"

# 5. CLEANUP: không còn container app-*
APP_REMAIN=$(docker ps -a --filter "label=asg=web-asg" -q | wc -l)
check "Tất cả app containers đã xóa (cleanup)" "$APP_REMAIN" "0" \
  "Chạy: for i in 1 2 3; do docker stop app-\$i && docker rm app-\$i; done"

# 6. Network đã xóa
NET_REMAIN=$(docker network ls --filter "name=app-network" -q | wc -l)
check "Network 'app-network' đã xóa" "$NET_REMAIN" "0" \
  "Chạy: docker network rm app-network"

# 7. LB config đã dọn
check "Nginx LB config đã xóa" \
  "$(test ! -f /etc/nginx/conf.d/lb.conf && echo ok)" "ok" \
  "Chạy: rm -f /etc/nginx/conf.d/lb.conf && nginx -s reload"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Scale-out thành công và cleanup hoàn tất!" && exit 0 || exit 1

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

check "[Bài tập] File /tmp/scaling-report.txt đã tạo" \
  "$(test -f /tmp/scaling-report.txt && echo ok)" "ok" \
  "Tạo file với python3 hoặc shell script từ bench-before.txt và bench-after.txt"

HAS_RPS=$(grep -ic "RPS\|req\|Requests" /tmp/scaling-report.txt 2>/dev/null)
check "[Bài tập] Report chứa thông tin RPS" \
  "$([ $HAS_RPS -ge 1 ] && echo ok)" "ok" \
  "Report phải có dòng 'RPS before' và 'RPS after'"

HAS_VERDICT=$(grep -ic "EFFECTIVE\|MARGINAL\|Verdict\|Improvement" /tmp/scaling-report.txt 2>/dev/null)
check "[Bài tập] Report có Verdict (EFFECTIVE/MARGINAL)" \
  "$([ $HAS_VERDICT -ge 1 ] && echo ok)" "ok" \
  "Thêm dòng Verdict: Scale-out EFFECTIVE hoặc MARGINAL"
