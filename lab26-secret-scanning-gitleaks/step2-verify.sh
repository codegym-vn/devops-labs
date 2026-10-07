#!/bin/bash

REPORT_FILE="/root/secret-leak-lab/gitleaks-history.json"

# Kiểm tra file config.json đã bị xóa khỏi working tree
if [ -f "/root/secret-leak-lab/config.json" ]; then
  echo "Tep 'config.json' van con ton tai trong Working Tree! Hay xoa va commit len Git."
  exit 1
fi

# Kiểm tra file báo cáo lịch sử tồn tại
if [ ! -f "$REPORT_FILE" ]; then
  echo "Chua tim thay tep bao cao '$REPORT_FILE'. Hay chay lenh: gitleaks detect --source . --report-path gitleaks-history.json"
  exit 1
fi

# Kiểm tra báo cáo lịch sử có ghi nhận commit cũ
if ! grep -q "AKIAIOSFODNN7EXAMPLE" "$REPORT_FILE"; then
  echo "Tep bao cao chua phat hien duoc khoa AWS trong lich su commit. Vui long kiem tra lai!"
  exit 1
fi

echo "Chuc mung! Ban da chung minh duoc kha nang truy vet secret trong lich su Git cua Gitleaks."
exit 0
