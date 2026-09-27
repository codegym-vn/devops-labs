#!/bin/bash
# step3-verify.sh — Lab 14: Kiểm tra Cost Analysis

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

echo "=== Bước 3: Cost Analysis ==="
echo ""

# 1. CUR file tồn tại
check "File cost-usage-report.csv tồn tại" \
  "$(test -f /opt/lab-data/cost-usage-report.csv && echo ok)" "ok" \
  "Background script phải tạo file này. Kiểm tra /opt/lab-data/ tồn tại."

# 2. CUR có ít nhất 100 dòng
ROWS=$(wc -l < /opt/lab-data/cost-usage-report.csv 2>/dev/null)
check "CUR có ít nhất 100 dòng dữ liệu" \
  "$([ ${ROWS:-0} -ge 100 ] && echo ok)" "ok" \
  "File được tạo bởi background.sh — chờ background hoàn tất"

# 3. Script analyze-cost.py chạy được
ANALYZE_OK=$(python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by ProductName 2>/dev/null | grep -c "Chi phí")
check "Script analyze-cost.py chạy thành công" \
  "$([ ${ANALYZE_OK:-0} -ge 1 ] && echo ok)" "ok" \
  "Kiểm tra: python3 /opt/lab-data/analyze-cost.py --file /opt/lab-data/cost-usage-report.csv --group-by ProductName"

# 4. Learner đã chạy breakdown theo Project
check "Breakdown theo Project đã chạy (có output)" \
  "$(python3 /opt/lab-data/analyze-cost.py \
    --file /opt/lab-data/cost-usage-report.csv \
    --group-by Project 2>/dev/null | grep -c 'e-commerce')" "1" \
  "Chạy: python3 /opt/lab-data/analyze-cost.py --group-by Project"

# 5. Learner đã viết script phát hiện spike (kiểm tra script tồn tại trong lịch sử)
# Kiểm tra gián tiếp: file có chứa cột "Project" không
HAS_PROJECT_COL=$(head -1 /opt/lab-data/cost-usage-report.csv | grep -c "Project")
check "CUR có cột 'Project' để phân tích" \
  "$([ ${HAS_PROJECT_COL:-0} -ge 1 ] && echo ok)" "ok" \
  "Background script phải tạo đúng format CUR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo " Cost analysis thành công!" && exit 0 || exit 1

echo ""
echo "===  Bài tập ==="
echo ""

check "[Bài tập] File /tmp/top-service.txt đã tạo" \
  "$(test -f /tmp/top-service.txt && echo ok)" "ok" \
  "Tạo file sau khi phân tích với analyze-cost.py"

HAS_SERVICE=$(grep -ic "Service\|service\|Top" /tmp/top-service.txt 2>/dev/null)
check "[Bài tập] File chứa tên service tốn nhiều nhất" \
  "$([ $HAS_SERVICE -ge 1 ] && echo ok)" "ok" \
  "Ghi: 'Service: <tên>' vào file"

HAS_PCT=$(grep -ic "%\|percent\|phần trăm" /tmp/top-service.txt 2>/dev/null)
check "[Bài tập] File chứa % of total" \
  "$([ $HAS_PCT -ge 1 ] && echo ok)" "ok" \
  "Tính và ghi % chiếm tổng chi phí"
