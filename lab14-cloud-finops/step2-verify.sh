#!/bin/bash
PASS=0; FAIL=0
check() { [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } || { echo "  ❌ $1"; FAIL=$((FAIL+1)); }; }
check_gt() { [ "$2" -gt "$3" ] 2>/dev/null && { echo "  ✅ $1 ($2 budgets)"; PASS=$((PASS+1)); } || { echo "  ❌ $1"; FAIL=$((FAIL+1)); }; }

echo "=== Kiểm tra Bước 2: AWS Budgets ==="
echo ""

ACCOUNT_ID="000000000000"
TOTAL=$(aws budgets describe-budgets --account-id $ACCOUNT_ID \
  --query 'length(Budgets)' --output text 2>/dev/null || echo "0")
check_gt "Có ít nhất 4 budgets (1 tổng + 3 theo project)" "$TOTAL" "3"

MAIN=$(aws budgets describe-budgets --account-id $ACCOUNT_ID \
  --query "Budgets[?BudgetName=='monthly-cloud-budget'].BudgetLimit.Amount" --output text 2>/dev/null)
check "Budget tổng 'monthly-cloud-budget' đặt \$100" "$MAIN" "100"

for PROJECT in "e-commerce" "data-platform" "internal-tools"; do
  B=$(aws budgets describe-budgets --account-id $ACCOUNT_ID \
    --query "Budgets[?BudgetName=='budget-${PROJECT}'].BudgetName" --output text 2>/dev/null)
  check "Budget 'budget-${PROJECT}' đã tạo" "$B" "budget-${PROJECT}"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 Budgets đã cấu hình! Tiếp tục Bước 3."; exit 0; } || { echo "⚠️  $FAIL lỗi."; exit 1; }
