#!/bin/bash
# step2-verify.sh — Kiểm tra ALB + Target Group + Docker containers + Nginx
source /tmp/lab-env.sh 2>/dev/null || true
PASS=0; FAIL=0

check() {
  [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } \
                  || { echo "  ❌ $1 (nhận: '$2', cần: '$3')"; FAIL=$((FAIL+1)); }
}
check_gt() {
  [ "$2" -gt "$3" ] 2>/dev/null && { echo "  ✅ $1"; PASS=$((PASS+1)); } \
                                || { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
}

echo "=== Kiểm tra Bước 2: ALB + Target Group + Nginx ==="
echo ""

# ALB tồn tại
ALB_STATE=$(aws elbv2 describe-load-balancers --names web-alb \
  --query 'LoadBalancers[0].State.Code' --output text 2>/dev/null)
check "ALB 'web-alb' đã tạo" "$ALB_STATE" "active"

# Target Group tồn tại
TG_NAME=$(aws elbv2 describe-target-groups --names web-tg \
  --query 'TargetGroups[0].TargetGroupName' --output text 2>/dev/null)
check "Target Group 'web-tg' đã tạo" "$TG_NAME" "web-tg"

# Health Check path đúng
HC_PATH=$(aws elbv2 describe-target-groups --names web-tg \
  --query 'TargetGroups[0].HealthCheckPath' --output text 2>/dev/null)
check "Health Check path là /health" "$HC_PATH" "/health"

# Listener tồn tại
LISTENER_PORT=$(aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers --names web-alb \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null) \
  --query 'Listeners[0].Port' --output text 2>/dev/null)
check "Listener trên port 80 đã tạo" "$LISTENER_PORT" "80"

# Docker containers app-1, app-2 đang chạy
for i in 1 2; do
  STATUS=$(docker inspect "app-${i}" --format '{{.State.Status}}' 2>/dev/null)
  check "Container 'app-${i}' đang chạy" "$STATUS" "running"
done

# Health endpoints của từng backend
for PORT in 8081 8082; do
  HC=$(curl -s http://localhost:${PORT}/health 2>/dev/null)
  check "Backend port ${PORT} health check OK" "$HC" "healthy"
done

# Nginx reload thành công và proxy hoạt động
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null)
check "Nginx ALB proxy phản hồi HTTP 200" "$HTTP_CODE" "200"

# Kiểm tra header X-Served-By (nginx đang proxy)
SERVED_BY=$(curl -s -I http://localhost/server-id 2>/dev/null | grep -i "x-served-by" | wc -l)
check_gt "Nginx thêm header X-Served-By (upstream routing)" "$SERVED_BY" "0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 ALB sẵn sàng! Tiếp tục Bước 3."; exit 0; } \
               || { echo "⚠️  $FAIL lỗi cần sửa."; exit 1; }
