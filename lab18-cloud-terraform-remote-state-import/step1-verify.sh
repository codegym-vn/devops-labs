#!/bin/bash
# step1-verify.sh — Lab 18: Kiểm tra cấu hình Remote Backend S3 & DynamoDB Locking

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

echo "=== Bước 1: Kiểm Tra Cấu Hình Remote Backend S3 & DynamoDB Locking ==="
echo ""

WORK_DIR="/root/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="/home/ubuntu/terraform-remote-lab"
[ -d "$WORK_DIR" ] || WORK_DIR="$(pwd)"
cd "$WORK_DIR" 2>/dev/null

# 1. Kiểm tra S3 Bucket devops-tfstate-bucket tồn tại
BUCKET_EXISTS="no"
if aws s3 ls "s3://devops-tfstate-bucket" >/dev/null 2>&1; then
  BUCKET_EXISTS="yes"
fi

check "S3 Bucket 'devops-tfstate-bucket' tồn tại trên Cloud" \
  "$BUCKET_EXISTS" "yes" \
  "Tạo S3 Bucket bằng lệnh 'aws s3api create-bucket --bucket devops-tfstate-bucket'"

# 2. Kiểm tra DynamoDB Table devops-tfstate-locks tồn tại
TABLE_STATUS=$(aws dynamodb describe-table \
  --table-name devops-tfstate-locks \
  --query "Table.TableStatus" \
  --output text 2>/dev/null)

check "DynamoDB Table 'devops-tfstate-locks' tồn tại và sẵn sàng (ACTIVE)" \
  "$TABLE_STATUS" "ACTIVE" \
  "Tạo bảng DynamoDB theo mục 2.1 với khóa chính LockID"

# 3. Kiểm tra file backend.tf tồn tại
HAS_BACKEND="no"
[ -f "backend.tf" ] && HAS_BACKEND="yes"

check "File cấu hình backend.tf tồn tại trong thư mục dự án" \
  "$HAS_BACKEND" "yes" \
  "Tạo file backend.tf khai báo backend S3 theo mục 2.3"

# 4. Kiểm tra object terraform.tfstate tồn tại trong S3 bucket
STATE_IN_S3="no"
if aws s3 ls "s3://devops-tfstate-bucket/network/terraform.tfstate" >/dev/null 2>&1; then
  STATE_IN_S3="yes"
fi

check "State file đã được di chuyển thành công lên 's3://devops-tfstate-bucket/network/terraform.tfstate'" \
  "$STATE_IN_S3" "yes" \
  "Chạy 'terraform init -migrate-state -force-copy' để di chuyển state lên S3"

# 5. Kiểm tra bài tập: Bucket Versioning đã được bật (Enabled)
VERSIONING_STATUS=$(aws s3api get-bucket-versioning \
  --bucket devops-tfstate-bucket \
  --query "Status" \
  --output text 2>/dev/null)

check "Bài tập: S3 Bucket đã bật tính năng Versioning (Status: Enabled)" \
  "$VERSIONING_STATUS" "Enabled" \
  "Chạy lệnh 'aws s3api put-bucket-versioning --bucket devops-tfstate-bucket --versioning-configuration Status=Enabled'"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " Hoàn thành Bước 1! Bạn đã chuyển đổi thành công sang Remote Backend chuẩn Enterprise."
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
