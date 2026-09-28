#!/bin/bash
# step1-verify.sh — Lab 12: Kiểm tra VPC, Subnet, IGW & Route Table với AWS CLI

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

echo "=== Bước 1: Kiểm Tra VPC & Hạ Tầng Mạng Cơ Bản ==="
echo ""

# 1. Kiểm tra VPC devops-vpc tồn tại và có CIDR 10.0.0.0/16
VPC_CIDR=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=devops-vpc" \
  --query "Vpcs[0].CidrBlock" --output text 2>/dev/null)

check "VPC 'devops-vpc' tồn tại với CIDR 10.0.0.0/16" \
  "$VPC_CIDR" "10.0.0.0/16" \
  "Chạy mục 1.1: aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-vpc}]'"

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=devops-vpc" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null)

# 2. Kiểm tra Public Subnet tồn tại (10.0.1.0/24)
PUB_CIDR=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=public-subnet" \
  --query "Subnet.CidrBlock" --output text 2>/dev/null)
if [ -z "$PUB_CIDR" ] || [ "$PUB_CIDR" = "None" ]; then
  PUB_CIDR=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=public-subnet" \
    --query "Subnets[0].CidrBlock" --output text 2>/dev/null)
fi

check "Subnet 'public-subnet' tồn tại với CIDR 10.0.1.0/24" \
  "$PUB_CIDR" "10.0.1.0/24" \
  "Chạy mục 1.2: aws ec2 create-subnet --vpc-id \$VPC_ID --cidr-block 10.0.1.0/24 ..."

# 3. Kiểm tra Private Subnet tồn tại (10.0.2.0/24)
PRIV_CIDR=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=private-subnet" \
  --query "Subnet.CidrBlock" --output text 2>/dev/null)
if [ -z "$PRIV_CIDR" ] || [ "$PRIV_CIDR" = "None" ]; then
  PRIV_CIDR=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=private-subnet" \
    --query "Subnets[0].CidrBlock" --output text 2>/dev/null)
fi

check "Subnet 'private-subnet' tồn tại với CIDR 10.0.2.0/24" \
  "$PRIV_CIDR" "10.0.2.0/24" \
  "Chạy mục 1.2: aws ec2 create-subnet --vpc-id \$VPC_ID --cidr-block 10.0.2.0/24 ..."

# 4. Kiểm tra Internet Gateway đã gắn vào VPC
IGW_ATTACHED=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[0].Attachments[0].State" --output text 2>/dev/null)

check "Internet Gateway đã gắn (attached) vào VPC" \
  "$IGW_ATTACHED" "available" \
  "Chạy mục 1.3: aws ec2 attach-internet-gateway --vpc-id \$VPC_ID --internet-gateway-id \$IGW_ID"

# 5. Kiểm tra Route Table cho Public Subnet có route 0.0.0.0/0
HAS_IGW_ROUTE=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=public-rt" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" --output text 2>/dev/null)

check "Route Table 'public-rt' có route 0.0.0.0/0 trỏ tới IGW" \
  "nonempty" "$HAS_IGW_ROUTE" \
  "Chạy mục 1.4: aws ec2 create-route --route-table-id \$RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id \$IGW_ID"

# 6. Kiểm tra bài tập: db-subnet (10.0.3.0/24)
DB_CIDR=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=db-subnet" \
  --query "Subnets[0].CidrBlock" --output text 2>/dev/null)

check "Bài tập: Subnet 'db-subnet' tồn tại với CIDR 10.0.3.0/24" \
  "$DB_CIDR" "10.0.3.0/24" \
  "Tạo subnet mới với --cidr-block 10.0.3.0/24 và tag Name=db-subnet"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Bạn đã xây dựng xong hạ tầng mạng VPC vững chắc."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
