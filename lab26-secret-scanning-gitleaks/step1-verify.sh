#!/bin/bash

REPORT_FILE="/root/secret-leak-lab/gitleaks-uncommitted.json"

# Kiểm tra tệp báo cáo tồn tại
if [ ! -f "$REPORT_FILE" ]; then
  echo "Chua tim thay tep bao cao '$REPORT_FILE'. Hay chay lenh: gitleaks detect --no-git --source . --report-path gitleaks-uncommitted.json"
  exit 1
fi

# Kiểm tra nội dung có chứa phát hiện secret
if ! grep -q "AKIAIOSFODNN7EXAMPLE" "$REPORT_FILE" && ! grep -q "aws-access-token" "$REPORT_FILE"; then
  echo "Tep bao cao chua chua thong tin phat hien lo khoa AWS. Vui long kiem tra lai!"
  exit 1
fi

echo "Chuc mung! Ban da thuc thi Gitleaks phat hien thong tin mat va xuat bao cao JSON thanh cong."
exit 0
