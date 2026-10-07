#!/bin/bash
set -e

# 1. Kiem tra container dang chay
if ! docker ps | grep -q "sonarqube"; then
  echo "Loi: Container 'sonarqube' chua chay tren he thong!"
  exit 1
fi

# 2. Kiem tra trang thai API he thong
STATUS=$(curl -s http://localhost:9000/api/system/status | jq -r '.status // empty' 2>/dev/null || true)
if [ "$STATUS" != "UP" ]; then
  echo "Loi: SonarQube Server chua o trang thai UP! Trang thai hien tai: $STATUS"
  exit 1
fi

# 3. Kiem tra xac thuc admin
VALID=$(curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/authentication/validate" | jq -r '.valid // empty' 2>/dev/null || true)
if [ "$VALID" != "true" ]; then
  # Thu mat khau cu admin:admin
  OLD_VALID=$(curl -u admin:admin -s "http://localhost:9000/api/authentication/validate" | jq -r '.valid // empty' 2>/dev/null || true)
  if [ "$OLD_VALID" != "true" ]; then
    echo "Loi: Khong the xac thuc tai khoan admin tren SonarQube!"
    exit 1
  fi
fi

echo "SonarQube Server san sang va xac thuc thanh cong!"
exit 0
