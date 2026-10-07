#!/bin/bash

FILE="/root/iac-security-lab/secure_resources.tf"

# Kiểm tra file secure_resources.tf có cấu hình public_web_sg
if ! grep -q "public_web_sg" "$FILE"; then
  echo "Chua tim thay tai nguyen 'public_web_sg' trong tệp '$FILE'!"
  exit 1
fi

# Kiểm tra chú thích checkov:skip
if ! grep -q "checkov:skip=CKV_AWS_260" "$FILE"; then
  echo "Chua tim thay chu thich bo qua cua Checkov (checkov:skip=CKV_AWS_260)!"
  exit 1
fi

# Kiểm tra chú thích tfsec:ignore
if ! grep -q "tfsec:ignore:aws-vpc-no-public-ingress-sgr" "$FILE"; then
  echo "Chua tim thay chu thich bo qua cua Tfsec (tfsec:ignore:aws-vpc-no-public-ingress-sgr)!"
  exit 1
fi

echo "Chuc mung! Ban da cau hinh co che bo qua ngoai le (Suppression) chinh xac theo chuan doanh nghiep."
exit 0
