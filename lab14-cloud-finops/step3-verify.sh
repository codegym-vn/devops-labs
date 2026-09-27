#!/bin/bash
PASS=0; FAIL=0
check() { [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } || { echo "  ❌ $1"; FAIL=$((FAIL+1)); }; }

echo "=== Kiểm tra Bước 3: Phân tích CUR ==="
echo ""

FILE_OK=$([ -f /opt/lab-data/cost-usage-report.csv ] && echo "yes" || echo "no")
check "File CUR tồn tại" "$FILE_OK" "yes"

LINE_COUNT=$(wc -l < /opt/lab-data/cost-usage-report.csv 2>/dev/null || echo "0")
[ "$LINE_COUNT" -gt 100 ] && { echo "  ✅ File CUR có $LINE_COUNT dòng (>100)"; PASS=$((PASS+1)); } || { echo "  ❌ File CUR quá nhỏ"; FAIL=$((FAIL+1)); }

SCRIPT_OK=$(python3 /opt/lab-data/analyze-cost.py --file /opt/lab-data/cost-usage-report.csv --group-by ProductName 2>/dev/null | grep -c "EC2" || echo "0")
[ "$SCRIPT_OK" -ge 1 ] && { echo "  ✅ Script phân tích chạy thành công"; PASS=$((PASS+1)); } || { echo "  ❌ Script phân tích lỗi"; FAIL=$((FAIL+1)); }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 Phân tích CUR hoàn thành! Tiếp tục Bước 4."; exit 0; } || { echo "⚠️  $FAIL lỗi."; exit 1; }
