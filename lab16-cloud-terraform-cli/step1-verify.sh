#!/bin/bash
# step1-verify.sh — Lab 16: Kiểm tra khởi tạo Project & Cấu hình Provider AWS

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

echo "=== Bước 1: Kiểm Tra Khởi Tạo Project & Cấu Hình Provider AWS ==="
echo ""

# Xác định thư mục làm việc
WORK_DIR="/root/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra file versions.tf tồn tại
HAS_VERSIONS="no"
[ -f "versions.tf" ] && HAS_VERSIONS="yes"

check "File cấu hình versions.tf tồn tại" \
  "$HAS_VERSIONS" "yes" \
  "Tạo file versions.tf theo mục 2.1 trong /root/terraform-lab"

# 2. Kiểm tra file provider.tf tồn tại
HAS_PROVIDER="no"
[ -f "provider.tf" ] && HAS_PROVIDER="yes"

check "File cấu hình provider.tf tồn tại" \
  "$HAS_PROVIDER" "yes" \
  "Tạo file provider.tf theo mục 2.2 trong /root/terraform-lab"

# 3. Kiểm tra .terraform.lock.hcl và thư mục .terraform tồn tại
HAS_LOCKFILE="no"
if [ -f ".terraform.lock.hcl" ] && grep -q "hashicorp/aws" ".terraform.lock.hcl"; then
  HAS_LOCKFILE="yes"
fi

check "File khóa phụ thuộc .terraform.lock.hcl tồn tại với Provider AWS" \
  "$HAS_LOCKFILE" "yes" \
  "Chạy lệnh 'terraform init' để tải provider và tạo lockfile"

# 4. Kiểm tra cấu hình hợp lệ qua terraform validate
VALIDATE_STATUS="fail"
if terraform validate >/dev/null 2>&1; then
  VALIDATE_STATUS="success"
fi

check "Lệnh 'terraform validate' phản hồi cú pháp HCL hợp lệ" \
  "$VALIDATE_STATUS" "success" \
  "Kiểm tra lại cú pháp các file .tf và chạy 'terraform validate'"

# 5. Kiểm tra bài tập: default_tags chứa Project = "devops-lab"
HAS_PROJECT_TAG="no"
if [ -f "provider.tf" ] && grep -i "Project" "provider.tf" | grep -q "devops-lab"; then
  HAS_PROJECT_TAG="yes"
fi

check "Bài tập: provider.tf cấu hình default_tags có Project = 'devops-lab'" \
  "$HAS_PROJECT_TAG" "yes" \
  "Mở provider.tf, thêm Project = \"devops-lab\" vào block default_tags và kiểm tra lại"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Bạn đã khởi tạo thành công môi trường Terraform chuẩn mực."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
