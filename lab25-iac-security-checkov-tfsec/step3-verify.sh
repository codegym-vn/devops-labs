#!/bin/bash

# Kiểm tra tệp cũ đã bị xóa
if [ -f "/root/iac-security-lab/insecure_resources.tf" ]; then
  echo "Tep 'insecure_resources.tf' van ton tai! Hay xoa bo tệp này."
  exit 1
fi

# Kiểm tra tệp mới tồn tại
if [ ! -f "/root/iac-security-lab/secure_resources.tf" ]; then
  echo "Chua tim thay tep 'secure_resources.tf'. Vui long kiem tra lai!"
  exit 1
fi

# Kiểm tra nội dung mã hóa AES256 và dải IP nội bộ
if ! grep -q "AES256" "/root/iac-security-lab/secure_resources.tf"; then
  echo "S3 Bucket chua duoc cau hinh ma hoa AES256!"
  exit 1
fi

if ! grep -q "10.0.0.0/16" "/root/iac-security-lab/secure_resources.tf"; then
  echo "Security Group chua duoc gioi han dai IP noi bo 10.0.0.0/16!"
  exit 1
fi

# Kiểm tra tfsec không còn lỗi
cd /root/iac-security-lab
if ! tfsec . > /dev/null 2>&1; then
  echo "tfsec van con phat hien loi trong ma nguon! Hay kiem tra lai cau hinh."
  exit 1
fi

echo "Chuc mung! Ban da khac phuc toan dien cac vi pham an ninh dat chuan CIS."
exit 0
