#!/bin/bash
# step3-verify.sh — Lab 12: Kiểm tra EC2 Instances & Key Pair với AWS CLI

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

echo "=== Bước 3: Kiểm Tra Máy Ảo EC2 & SSH Key Pair ==="
echo ""

# 1. Kiểm tra Key Pair devops-key tồn tại trên AWS
KEY_NAME=$(aws ec2 describe-key-pairs \
  --key-names devops-key \
  --query "KeyPairs[0].KeyName" --output text 2>/dev/null)

check "SSH Key Pair 'devops-key' đã được tạo trên AWS" \
  "$KEY_NAME" "devops-key" \
  "Chạy mục 3.1: aws ec2 create-key-pair --key-name devops-key ..."

# 2. Kiểm tra file private key đã lưu tại /tmp/devops-key.pem
check "File private key /tmp/devops-key.pem tồn tại cục bộ" \
  "$(test -f /tmp/devops-key.pem && echo ok)" "ok" \
  "Lưu output của create-key-pair vào file /tmp/devops-key.pem"

# 3. Lấy Subnet IDs và SG IDs để kiểm tra
source /tmp/lab-env.sh 2>/dev/null

PUB_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=public-subnet" \
  --query "Subnets[0].SubnetId" --output text 2>/dev/null)

PRIV_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=private-subnet" \
  --query "Subnets[0].SubnetId" --output text 2>/dev/null)

WEB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=web-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

DB_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=db-sg" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null)

# 4. Kiểm tra web-server-1 trong Public Subnet với web-sg
WEB1_SUBNET=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server-1" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].SubnetId" --output text 2>/dev/null)

check "Instance 'web-server-1' đang chạy trong Public Subnet" \
  "$WEB1_SUBNET" "$PUB_SUBNET_ID" \
  "Chạy mục 3.2: aws ec2 run-instances --subnet-id \$PUB_SUBNET_ID ..."

WEB1_SG=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server-1" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Instance 'web-server-1' được bảo vệ bởi 'web-sg'" \
  "$WEB1_SG" "$WEB_SG_ID" \
  "Gán --security-group-ids \$WEB_SG_ID khi khởi tạo web-server-1"

# 5. Kiểm tra db-server-1 trong Private Subnet với db-sg
DB1_SUBNET=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=db-server-1" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].SubnetId" --output text 2>/dev/null)

check "Instance 'db-server-1' đang chạy trong Private Subnet" \
  "$DB1_SUBNET" "$PRIV_SUBNET_ID" \
  "Chạy mục 3.3: aws ec2 run-instances --subnet-id \$PRIV_SUBNET_ID ..."

DB1_SG=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=db-server-1" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text 2>/dev/null)

check "Instance 'db-server-1' được bảo vệ bởi 'db-sg'" \
  "$DB1_SG" "$DB_SG_ID" \
  "Gán --security-group-ids \$DB_SG_ID khi khởi tạo db-server-1"

# 6. Kiểm tra bài tập: web-server-2 tồn tại trong Public Subnet
WEB2_SUBNET=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server-2" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].SubnetId" --output text 2>/dev/null)

check "Bài tập: Instance 'web-server-2' đã chạy trong Public Subnet" \
  "$WEB2_SUBNET" "$PUB_SUBNET_ID" \
  "Khởi tạo instance thứ hai với tag Name=web-server-2 trong Public Subnet"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 3! Bạn đã triển khai thành công cụm máy ảo EC2 vào các phân vùng mạng."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
