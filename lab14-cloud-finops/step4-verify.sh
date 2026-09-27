#!/bin/bash
# step4-verify.sh — Lab 14: Kiểm tra Idle Detection + Report

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

echo "=== Bước 4: Idle Detection + Optimization Report ==="
echo ""

# 1. Script find-idle-resources.py chạy được
IDLE_OK=$(python3 /opt/lab-data/find-idle-resources.py \
  --metrics /opt/lab-data/resource-utilization.json \
  --cpu-threshold 30 2>/dev/null | grep -c "Phân tích")
check "Script find-idle-resources.py chạy thành công" \
  "$([ ${IDLE_OK:-0} -ge 1 ] && echo ok)" "ok" \
  "Kiểm tra: python3 /opt/lab-data/find-idle-resources.py --metrics /opt/lab-data/resource-utilization.json --cpu-threshold 30"

# 2. Phát hiện đúng servers idle (CPU < 30%)
IDLE_COUNT=$(python3 /opt/lab-data/find-idle-resources.py \
  --metrics /opt/lab-data/resource-utilization.json \
  --cpu-threshold 30 2>/dev/null | grep -c "idle\|Downgrade\|TERMINATE")
check "Phát hiện ít nhất 2 servers idle (CPU < 30%)" \
  "$([ ${IDLE_COUNT:-0} -ge 2 ] && echo ok)" "ok" \
  "Dataset có worker-prod (8.3%), reporting-server (3.1%), old-test-server (1.2%) — đều idle"

# 3. Báo cáo tối ưu đã tạo
check "Báo cáo tối ưu /tmp/finops-report.md đã tạo" \
  "$(test -f /tmp/finops-report.md && echo ok)" "ok" \
  "Chạy phần 4.3 để tạo báo cáo"

# 4. Báo cáo có đề xuất Terminate
SUGGEST_TERMINATE=$(grep -c -i "terminate\|xóa\|TERMINATE" /tmp/finops-report.md 2>/dev/null)
check "Báo cáo có đề xuất TERMINATE cho servers idle nặng" \
  "$([ ${SUGGEST_TERMINATE:-0} -ge 1 ] && echo ok)" "ok" \
  "Thêm đề xuất Terminate cho old-test-server (CPU 1.2%)"

# 5. Báo cáo tính được % tiết kiệm
HAS_SAVINGS=$(grep -c -i "tiết kiệm\|saving\|\%" /tmp/finops-report.md 2>/dev/null)
check "Báo cáo có ước tính % tiết kiệm" \
  "$([ ${HAS_SAVINGS:-0} -ge 1 ] && echo ok)" "ok" \
  "Thêm mục 'Tiết kiệm ước tính' với % vào báo cáo"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
if [ $FAIL -eq 0 ]; then
  echo "🎉 FinOps Lab hoàn thành!"
  echo "   Bạn đã thực hành đầy đủ: Tagging → Budgets → Cost Analysis → Optimization"
  exit 0
else
  exit 1
fi

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

HAS_API_SECTION=$(grep -ic "api-server-prod" /tmp/finops-report.md 2>/dev/null)
check "[Bài tập] Báo cáo có section về api-server-prod" \
  "$([ $HAS_API_SECTION -ge 1 ] && echo ok)" "ok" \
  "Thêm section 'Đề xuất bổ sung: api-server-prod' vào /tmp/finops-report.md"

HAS_RESERVED=$(grep -ic "Reserved\|Savings Plans\|tiết kiệm\|saving" /tmp/finops-report.md 2>/dev/null)
check "[Bài tập] Đề xuất có giải pháp tối ưu (Reserved/Savings Plans)" \
  "$([ $HAS_RESERVED -ge 1 ] && echo ok)" "ok" \
  "Thêm đề xuất Reserved Instance hoặc Savings Plans với % tiết kiệm"

HAS_RISK=$(grep -ic "rủi ro\|risk\|Rủi ro" /tmp/finops-report.md 2>/dev/null)
check "[Bài tập] Đề xuất có phân tích rủi ro" \
  "$([ $HAS_RISK -ge 1 ] && echo ok)" "ok" \
  "Thêm dòng 'Rủi ro: ...' vào đề xuất"
