#!/bin/bash
source /tmp/lab-env.sh 2>/dev/null || true
PASS=0; FAIL=0
check() { [ "$2" = "$3" ] && { echo "  ✅ $1"; PASS=$((PASS+1)); } || { echo "  ❌ $1 (cần: '$3', nhận: '$2')"; FAIL=$((FAIL+1)); }; }

echo "=== Kiểm tra Bước 1: Cost Allocation Tags ==="
echo ""
for INST_VAR in INST_0 INST_1 INST_2 INST_3 INST_4; do
  INST=${!INST_VAR}
  for TAG in Name Project Environment Owner; do
    VAL=$(aws ec2 describe-instances --instance-ids $INST \
      --query "Reservations[0].Instances[0].Tags[?Key=='$TAG'].Value" --output text 2>/dev/null)
    [ -n "$VAL" ] && { echo "  ✅ $INST có tag $TAG=$VAL"; PASS=$((PASS+1)); } \
                  || { echo "  ❌ $INST thiếu tag $TAG"; FAIL=$((FAIL+1)); }
  done
done

# VPC có tag Project
VPC_TAG=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
  --query "Vpcs[0].Tags[?Key=='Project'].Value" --output text 2>/dev/null)
check "VPC có tag Project" "$VPC_TAG" "e-commerce"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && { echo "🎉 Tags đã gắn đúng! Tiếp tục Bước 2."; exit 0; } || { echo "⚠️  $FAIL lỗi."; exit 1; }
