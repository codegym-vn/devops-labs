#!/bin/bash

REPORT_FILE="/root/iac-security-lab/checkov-report.json"

# Kiểm tra file báo cáo checkov tồn tại
if [ ! -f "$REPORT_FILE" ]; then
  echo "Chua tim thay tep bao cao '$REPORT_FILE'. Hay chay lenh: checkov -d . --framework terraform -o json > checkov-report.json"
  exit 1
fi

# Kiểm tra nội dung báo cáo có chứa kết quả quét của checkov
if ! grep -q "CKV_AWS_" "$REPORT_FILE"; then
  echo "Tep bao cao chua chua ket qua phan tich cua Checkov. Vui long kiem tra lai!"
  exit 1
fi

echo "Chuc mung! Ban da thuc thi Checkov va xuat bao cao phan tich thanh cong."
exit 0
