#!/bin/bash
# step2-verify.sh — Lab 16: Kiểm tra khai báo VPC, Subnet, Variables & Outputs

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

echo "=== Bước 2: Kiểm Tra Khai Báo Mạng VPC, Subnet, Variables & Outputs ==="
echo ""

WORK_DIR="/root/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra các file .tf cần thiết tồn tại
HAS_FILES="yes"
for f in variables.tf vpc.tf outputs.tf; do
  if [ ! -f "$f" ]; then
    HAS_FILES="no"
    break
  fi
done

check "Các file variables.tf, vpc.tf, outputs.tf tồn tại đầy đủ" \
  "$HAS_FILES" "yes" \
  "Tạo đủ các file theo hướng dẫn mục 2.1, 2.2, 2.3"

# 2. Kiểm tra tính hợp lệ bằng terraform validate
VALIDATE_RESULT="fail"
if terraform validate >/dev/null 2>&1; then
  VALIDATE_RESULT="success"
fi

check "Lệnh 'terraform validate' xác nhận toàn bộ cấu hình hợp lệ" \
  "$VALIDATE_RESULT" "success" \
  "Chạy 'terraform validate' để xem chi tiết lỗi cú pháp hoặc thuộc tính sai"

# 3. Kiểm tra resource aws_vpc và aws_subnet.public trong vpc.tf
HAS_CORE_RESOURCES="no"
if grep -q 'resource[[:space:]]*"aws_vpc"[[:space:]]*"main"' vpc.tf 2>/dev/null && \
   grep -q 'resource[[:space:]]*"aws_subnet"[[:space:]]*"public"' vpc.tf 2>/dev/null; then
  HAS_CORE_RESOURCES="yes"
fi

check "File vpc.tf khai báo đúng resource aws_vpc.main và aws_subnet.public" \
  "$HAS_CORE_RESOURCES" "yes" \
  "Kiểm tra lại tên resource trong file vpc.tf"

# 4. Kiểm tra outputs cơ bản (vpc_id, public_subnet_id)
HAS_CORE_OUTPUTS="no"
if grep -q 'output[[:space:]]*"vpc_id"' outputs.tf 2>/dev/null && \
   grep -q 'output[[:space:]]*"public_subnet_id"' outputs.tf 2>/dev/null; then
  HAS_CORE_OUTPUTS="yes"
fi

check "File outputs.tf khai báo vpc_id và public_subnet_id" \
  "$HAS_CORE_OUTPUTS" "yes" \
  "Khai báo output \"vpc_id\" và output \"public_subnet_id\" trong outputs.tf"

# 5. Kiểm tra bài tập: biến private_subnet_cidr và resource aws_subnet.private
HAS_PRIVATE_SUBNET="no"
if grep -q 'private_subnet_cidr' variables.tf 2>/dev/null && \
   grep -q 'resource[[:space:]]*"aws_subnet"[[:space:]]*"private"' vpc.tf 2>/dev/null && \
   grep -q 'output[[:space:]]*"private_subnet_id"' outputs.tf 2>/dev/null; then
  HAS_PRIVATE_SUBNET="yes"
fi

check "Bài tập: Khai báo đầy đủ private_subnet_cidr, resource aws_subnet.private và output private_subnet_id" \
  "$HAS_PRIVATE_SUBNET" "yes" \
  "Làm bài tập ở mục 3: thêm biến vào variables.tf, resource vào vpc.tf và output vào outputs.tf"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Bạn đã thiết kế thành công mô đun hạ tầng mạng ảo chuẩn HCL."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
