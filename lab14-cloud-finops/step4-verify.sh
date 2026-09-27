#!/bin/bash
PASS=0; FAIL=0
check() { [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } || { echo "  ❌ $1"; FAIL=$((FAIL+1)); }; }

echo "=== Kiểm tra Bước 4: Idle Analysis + FinOps Report ==="
echo ""

UTIL_OK=$(python3 /opt/lab-data/find-idle-resources.py --metrics /opt/lab-data/resource-utilization.json --cpu-threshold 30 2>/dev/null | grep -c "Downgrade\|NGƯNG\|Tiết kiệm" || echo "0")
[ "$UTIL_OK" -ge 2 ] && { echo "  ✅ Script idle analysis phát hiện ít nhất 2 recommendations"; PASS=$((PASS+1)); } || { echo "  ❌ Script cần phát hiện >=2 recommendations"; FAIL=$((FAIL+1)); }

REPORT_OK=$([ -f /tmp/finops-report.md ] && echo "yes" || echo "no")
check "Báo cáo FinOps đã được tạo (/tmp/finops-report.md)" "$REPORT_OK" "yes"

SAVINGS=$(grep -i "tiết kiệm\|savings" /tmp/finops-report.md 2>/dev/null | wc -l)
[ "$SAVINGS" -ge 1 ] && { echo "  ✅ Báo cáo có phần đề xuất tiết kiệm"; PASS=$((PASS+1)); } || { echo "  ❌ Báo cáo thiếu phần đề xuất"; FAIL=$((FAIL+1)); }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🏆 Hoàn thành Lab 14 — FinOps!"; exit 0; } || { echo "⚠️  $FAIL lỗi."; exit 1; }
