#!/bin/bash
# step2-verify.sh — Lab 17: Kiểm tra đóng gói module compute & kết nối liên module

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

echo "=== Bước 2: Kiểm Tra Đóng Gói Module Compute & Kết Nối Liên Module ==="
echo ""

WORK_DIR="/root/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-workspaces-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra cấu hình modules/compute
HAS_COMPUTE_FILES="yes"
for f in modules/compute/main.tf modules/compute/variables.tf modules/compute/outputs.tf; do
  if [ ! -f "$f" ]; then
    HAS_COMPUTE_FILES="no"
    break
  fi
done

check "Thư mục modules/compute có đủ main.tf, variables.tf và outputs.tf" \
  "$HAS_COMPUTE_FILES" "yes" \
  "Tạo module compute theo mục 2.1"

# 2. Kiểm tra Root module có đủ variables.tf, main.tf, outputs.tf
HAS_ROOT_FILES="yes"
for f in variables.tf main.tf outputs.tf; do
  if [ ! -f "$f" ]; then
    HAS_ROOT_FILES="no"
    break
  fi
done

check "Root module có đầy đủ variables.tf, main.tf và outputs.tf" \
  "$HAS_ROOT_FILES" "yes" \
  "Tạo các file tại thư mục gốc theo mục 2.2"

# 3. Kiểm tra main.tf ở Root gọi cả 2 module vpc và compute
HAS_MODULE_CALLS="no"
if grep -q 'module[[:space:]]*"vpc"' main.tf 2>/dev/null && \
   grep -q 'module[[:space:]]*"compute"' main.tf 2>/dev/null; then
  HAS_MODULE_CALLS="yes"
fi

check "File main.tf ở Root gọi thành công module 'vpc' và module 'compute'" \
  "$HAS_MODULE_CALLS" "yes" \
  "Khai báo block module \"vpc\" và module \"compute\" trong main.tf"

# 4. Kiểm tra terraform validate
VALIDATE_STATUS="fail"
if terraform validate >/dev/null 2>&1; then
  VALIDATE_STATUS="success"
fi

check "Lệnh 'terraform validate' xác nhận toàn bộ kiến trúc module hợp lệ" \
  "$VALIDATE_STATUS" "success" \
  "Chạy 'terraform init' rồi 'terraform validate' để kiểm tra lỗi liên kết"

# 5. Kiểm tra bài tập: port 443 trong modules/compute/main.tf
HAS_PORT_443="no"
if grep -q "443" modules/compute/main.tf 2>/dev/null; then
  HAS_PORT_443="yes"
fi

check "Bài tập: modules/compute/main.tf cấu hình mở cổng HTTPS (port 443)" \
  "$HAS_PORT_443" "yes" \
  "Bổ sung block ingress mở cổng 443 vào Security Group trong modules/compute/main.tf"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 2! Bạn đã kết nối thành công các Child Modules độc lập."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
