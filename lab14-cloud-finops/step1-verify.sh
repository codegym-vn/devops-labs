#!/bin/bash
# step1-verify.sh — Lab 14: Kiểm tra Tagging

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

check_label() {
  local CONTAINER=$1 LABEL=$2 EXPECTED=$3
  VALUE=$(docker inspect $CONTAINER --format "{{index .Config.Labels \"$LABEL\"}}" 2>/dev/null)
  check "$CONTAINER có label $LABEL=$EXPECTED" \
    "$VALUE" "$EXPECTED" \
    "Thêm --label $LABEL=$EXPECTED khi tạo container $CONTAINER"
}

echo "=== Bước 1: Cost Allocation Tags ==="
echo ""

CONTAINERS="api-server-prod web-server-prod worker-prod reporting-server old-test-server"

# Kiểm tra từng container tồn tại và có đủ 5 tags chuẩn
for C in $CONTAINERS; do
  STATUS=$(docker inspect $C --format '{{.State.Status}}' 2>/dev/null)
  check "Container '$C' đang running" "$STATUS" "running" \
    "Chạy lại hàm create_server để tạo $C"
done

echo ""
echo "  Kiểm tra tags chuẩn:"

# Kiểm tra api-server-prod
check_label "api-server-prod" "Project" "e-commerce"
check_label "api-server-prod" "Environment" "production"
check_label "api-server-prod" "Owner" "team-backend"

# Kiểm tra worker-prod (phải là data-platform)
check_label "worker-prod" "Project" "data-platform"

# Kiểm tra old-test-server (phải có Project tag sau phần 1.3)
check_label "old-test-server" "Project" "internal-tools"
check_label "old-test-server" "Environment" "development"

# Kiểm tra query theo tag hoạt động
ECOMMERCE_COUNT=$(docker ps --filter "label=Project=e-commerce" -q | wc -l)
check "Có ít nhất 2 servers thuộc Project 'e-commerce'" \
  "$([ $ECOMMERCE_COUNT -ge 2 ] && echo ok)" "ok" \
  "Tạo api-server-prod và web-server-prod với --label Project=e-commerce"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Tagging đúng chuẩn!" && exit 0 || exit 1

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

SEC_STATUS=$(docker inspect security-scanner --format '{{.State.Status}}' 2>/dev/null)
check "[Bài tập] Container 'security-scanner' đang running" "$SEC_STATUS" "running" \
  "create_server 'security-scanner' 'security-tools' 'production' 'team-security' 'CC-004'"

for TAG in "Project=security-tools" "Owner=team-security" "CostCenter=CC-004"; do
  KEY="${TAG%%=*}"; VAL="${TAG##*=}"
  ACTUAL=$(docker inspect security-scanner --format "{{index .Config.Labels \"$KEY\"}}" 2>/dev/null)
  check "[Bài tập] security-scanner có label $KEY=$VAL" "$ACTUAL" "$VAL" \
    "Thêm --label $KEY=$VAL khi tạo container"
done

SEC_OWNER_COUNT=$(docker ps --filter "label=Owner=team-security" -q | wc -l)
check "[Bài tập] Đúng 1 container thuộc Owner=team-security" \
  "$([ $SEC_OWNER_COUNT -eq 1 ] && echo ok)" "ok" \
  "Chỉ security-scanner phải có label Owner=team-security"
