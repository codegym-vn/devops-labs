#!/bin/bash
# step2-verify.sh — Lab 14: Kiểm tra Budget setup

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

echo "=== Bước 2: Budget Alerts ==="
echo ""

# 1. File budget config tồn tại
check "File /opt/lab-data/budgets/config.json đã tạo" \
  "$(test -f /opt/lab-data/budgets/config.json && echo ok)" "ok" \
  "Chạy phần 2.1 để tạo file config.json"

# 2. Config JSON hợp lệ
JSON_VALID=$(python3 -c "import json; json.load(open('/opt/lab-data/budgets/config.json'))" 2>/dev/null && echo ok)
check "config.json là JSON hợp lệ" "$JSON_VALID" "ok" \
  "Kiểm tra cú pháp JSON: python3 -m json.tool /opt/lab-data/budgets/config.json"

# 3. Có ít nhất 3 budget (total + 2 project)
if [ "$JSON_VALID" = "ok" ]; then
  BUDGET_COUNT=$(python3 -c "
import json
data = json.load(open('/opt/lab-data/budgets/config.json'))
print(len(data.get('budgets', [])))
" 2>/dev/null)
  check "Có ít nhất 3 budget entries (total + projects)" \
    "$([ ${BUDGET_COUNT:-0} -ge 3 ] && echo ok)" "ok" \
    "Thêm budget entries cho total, e-commerce, data-platform, internal-tools"

  # 4. Budget total-monthly có limit $300
  TOTAL_LIMIT=$(python3 -c "
import json
data = json.load(open('/opt/lab-data/budgets/config.json'))
b = next((x for x in data['budgets'] if x['name']=='total-monthly'), None)
print(b['limit_usd'] if b else 0)
" 2>/dev/null)
  check "Budget 'total-monthly' có limit \$300" \
    "$([ ${TOTAL_LIMIT:-0} -eq 300 ] && echo ok)" "ok" \
    "Đặt limit_usd: 300 trong budget total-monthly"

  # 5. Có alert 80% ACTUAL
  HAS_80=$(python3 -c "
import json
data = json.load(open('/opt/lab-data/budgets/config.json'))
for b in data['budgets']:
  for a in b.get('alerts',[]):
    if a.get('threshold_pct')==80 and a.get('type')=='ACTUAL':
      print('ok'); exit()
" 2>/dev/null)
  check "Có alert ACTUAL tại 80% trong ít nhất 1 budget" \
    "$HAS_80" "ok" \
    "Thêm alert với threshold_pct: 80, type: ACTUAL"
fi

# 6. Script check-budget.py tồn tại và chạy được
check "Script /opt/lab-data/budgets/check-budget.py đã tạo" \
  "$(test -f /opt/lab-data/budgets/check-budget.py && echo ok)" "ok" \
  "Chạy phần 2.2 để tạo check-budget.py"

# 7. Cron job đã thiết lập
CRON_SET=$(cat /etc/cron.d/budget-check 2>/dev/null | grep -c "check-budget.py")
check "Cron job kiểm tra budget đã thiết lập" \
  "$([ ${CRON_SET:-0} -ge 1 ] && echo ok)" "ok" \
  "Chạy phần 2.3 để tạo /etc/cron.d/budget-check"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Budget alerts đã cấu hình đúng!" && exit 0 || exit 1
