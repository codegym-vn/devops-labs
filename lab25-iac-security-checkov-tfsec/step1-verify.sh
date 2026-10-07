#!/bin/bash

REPORT_FILE="/root/iac-security-lab/tfsec-report.json"

# Kiểm tra file báo cáo tfsec tồn tại
if [ ! -f "$REPORT_FILE" ]; then
  echo "Chua tim thay tep bao cao '$REPORT_FILE'. Hay chay lenh: tfsec . --format json --out tfsec-report.json"
  exit 1
fi

# Kiểm tra nội dung báo cáo có chứa kết quả phát hiện lỗi
if ! grep -q "aws-vpc-no-public-ingress-sgr" "$REPORT_FILE" && ! grep -q "aws-s3-enable-bucket-encryption" "$REPORT_FILE"; then
  echo "Tep bao cao chua chua ket qua quet loi cua tfsec. Vui long kiem tra lai!"
  exit 1
fi

echo "Chuc mung! Ban da thuc thi tfsec va xuat bao cao JSON thanh cong."
exit 0
