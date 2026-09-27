#!/bin/bash
# step1-verify.sh — Kiểm tra Bước 1: VPC + Subnet + IGW + Route Table

source /tmp/lab-env.sh 2>/dev/null || true

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  local expected="$3"
  if [ "$result" = "$expected" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc (nhận: '$result', cần: '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Kiểm tra Bước 1: Hạ tầng mạng VPC ==="
echo ""

# 1. VPC tồn tại với CIDR đúng
VPC_CIDR=$(aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'Vpcs[0].CidrBlock' --output text 2>/dev/null)
check "VPC với CIDR 10.0.0.0/16 đã được tạo" "$VPC_CIDR" "10.0.0.0/16"

# 2. Subnet tồn tại với CIDR đúng
SUBNET_CIDR=$(aws ec2 describe-subnets \
  --filters "Name=cidr,Values=10.0.1.0/24" \
  --query 'Subnets[0].CidrBlock' --output text 2>/dev/null)
check "Subnet với CIDR 10.0.1.0/24 đã được tạo" "$SUBNET_CIDR" "10.0.1.0/24"

# 3. Subnet bật MapPublicIpOnLaunch
MAP_PUBLIC=$(aws ec2 describe-subnets \
  --filters "Name=cidr,Values=10.0.1.0/24" \
  --query 'Subnets[0].MapPublicIpOnLaunch' --output text 2>/dev/null)
check "Subnet bật tự động gán Public IP" "$MAP_PUBLIC" "True"

# 4. Internet Gateway tồn tại và đã gắn vào VPC
IGW_STATE=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$(aws ec2 describe-vpcs \
    --filters "Name=cidr,Values=10.0.0.0/16" \
    --query 'Vpcs[0].VpcId' --output text 2>/dev/null)" \
  --query 'InternetGateways[0].Attachments[0].State' --output text 2>/dev/null)
check "Internet Gateway đã gắn vào VPC" "$IGW_STATE" "available"

# 5. Route Table có route 0.0.0.0/0 qua IGW
VPC_ID_CHECK=$(aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
ROUTE_DEST=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID_CHECK" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].DestinationCidrBlock" \
  --output text 2>/dev/null)
check "Route Table có route 0.0.0.0/0 qua Internet Gateway" "$ROUTE_DEST" "0.0.0.0/0"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS thành công / $((PASS + FAIL)) kiểm tra"

if [ $FAIL -eq 0 ]; then
  echo "🎉 Tất cả đều đúng! Tiếp tục Bước 2."
  exit 0
else
  echo "⚠️  Có $FAIL lỗi cần sửa. Đọc lại hướng dẫn và thử lại."
  exit 1
fi
