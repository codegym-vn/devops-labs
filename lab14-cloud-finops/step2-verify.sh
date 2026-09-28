#!/bin/bash
# step2-verify.sh — Lab 14: Kiểm tra cấu hình AWS Budgets

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

echo "=== Bước 2: Kiểm Tra Cấu Hình AWS Budgets ==="
echo ""

CONFIG_FILE="/opt/lab-data/budgets/config.json"

check "File cấu hình /opt/lab-data/budgets/config.json tồn tại" \
  "$(test -f $CONFIG_FILE && echo ok)" "ok" \
  "Tạo file theo hướng dẫn mục 2.1"

# Kiểm tra budget tổng thể
TOTAL_LIMIT=$(jq -r '.budgets[] | select(.name=="total-monthly-budget") | .limit_usd' $CONFIG_FILE 2>/dev/null)
check "Budget 'total-monthly-budget' có limit_usd = 300" \
  "$TOTAL_LIMIT" "300" \
  "Cấu hình total-monthly-budget với limit_usd: 300"

# Kiểm tra e-commerce budget
ECOM_LIMIT=$(jq -r '.budgets[] | select(.name=="project-e-commerce") | .limit_usd' $CONFIG_FILE 2>/dev/null)
check "Budget 'project-e-commerce' có limit_usd = 150" \
  "$ECOM_LIMIT" "150" \
  "Cấu hình project-e-commerce với limit_usd: 150"

# Kiểm tra data-platform budget
DATA_LIMIT=$(jq -r '.budgets[] | select(.name=="project-data-platform") | .limit_usd' $CONFIG_FILE 2>/dev/null)
check "Budget 'project-data-platform' có limit_usd = 80" \
  "$DATA_LIMIT" "80" \
  "Cấu hình project-data-platform với limit_usd: 80"

# Kiểm tra bài tập: project-internal-tools
INTERNAL_LIMIT=$(jq -r '.budgets[] | select(.name=="project-internal-tools") | .limit_usd' $CONFIG_FILE 2>/dev/null)
check "Bài tập: Budget 'project-internal-tools' có limit_usd = 50" \
  "$INTERNAL_LIMIT" "50" \
  "Thêm budget cho project-internal-tools với limit_usd: 50 theo yêu cầu bài tập"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Cấu hình cảnh báo ngân sách AWS Budgets đã đạt chuẩn."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
