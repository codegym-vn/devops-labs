#!/bin/bash
# step1-verify.sh — Lab 17: Kiểm tra cấu hình Root & Child Module modules/vpc

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

echo "=== Bước 1: Kiểm Tra Cấu Hình Root & Child Module modules/vpc ==="
echo ""

WORK_DIR="/root/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra cấu hình Root: versions.tf và provider.tf
HAS_ROOT_FILES="yes"
for f in versions.tf provider.tf; do
  if [ ! -f "$f" ]; then
    HAS_ROOT_FILES="no"
    break
  fi
done

check "Root module có đầy đủ versions.tf và provider.tf" \
  "$HAS_ROOT_FILES" "yes" \
  "Tạo versions.tf và provider.tf ở thư mục gốc theo mục 2.1"

# 2. Kiểm tra thư mục modules/vpc và các file bên trong
HAS_MODULE_FILES="yes"
for f in modules/vpc/main.tf modules/vpc/variables.tf modules/vpc/outputs.tf; do
  if [ ! -f "$f" ]; then
    HAS_MODULE_FILES="no"
    break
  fi
done

check "Thư mục modules/vpc chứa đầy đủ main.tf, variables.tf và outputs.tf" \
  "$HAS_MODULE_FILES" "yes" \
  "Khởi tạo module vpc theo mục 2.2, 2.3, 2.4"

# 3. Kiểm tra biến đầu vào của module vpc
HAS_VPC_VARS="no"
if grep -q "env_name" modules/vpc/variables.tf 2>/dev/null && \
   grep -q "vpc_cidr" modules/vpc/variables.tf 2>/dev/null && \
   grep -q "public_subnet_cidr" modules/vpc/variables.tf 2>/dev/null; then
  HAS_VPC_VARS="yes"
fi

check "File modules/vpc/variables.tf khai báo đúng các biến env_name, vpc_cidr, public_subnet_cidr" \
  "$HAS_VPC_VARS" "yes" \
  "Kiểm tra lại khai báo biến trong modules/vpc/variables.tf"

# 4. Kiểm tra tài nguyên aws_vpc và aws_subnet trong modules/vpc/main.tf
HAS_VPC_RESOURCES="no"
if grep -q 'resource[[:space:]]*"aws_vpc"[[:space:]]*"this"' modules/vpc/main.tf 2>/dev/null && \
   grep -q 'resource[[:space:]]*"aws_subnet"[[:space:]]*"public"' modules/vpc/main.tf 2>/dev/null; then
  HAS_VPC_RESOURCES="yes"
fi

check "File modules/vpc/main.tf khai báo aws_vpc.this và aws_subnet.public" \
  "$HAS_VPC_RESOURCES" "yes" \
  "Kiểm tra lại logic tài nguyên trong modules/vpc/main.tf"

# 5. Kiểm tra bài tập: output vpc_cidr_block trong modules/vpc/outputs.tf
HAS_CIDR_OUTPUT="no"
if grep -q 'output[[:space:]]*"vpc_cidr_block"' modules/vpc/outputs.tf 2>/dev/null; then
  HAS_CIDR_OUTPUT="yes"
fi

check "Bài tập: modules/vpc/outputs.tf xuất output vpc_cidr_block" \
  "$HAS_CIDR_OUTPUT" "yes" \
  "Bổ sung output vpc_cidr_block vào modules/vpc/outputs.tf theo bài tập mục 3"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Bạn đã đóng gói thành công Child Module mạng chuẩn mực."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
