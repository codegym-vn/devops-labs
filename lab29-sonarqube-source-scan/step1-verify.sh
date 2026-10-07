#!/bin/bash

# 1. Container sonarqube dang chay
if ! docker ps --format '{{.Names}}' | grep -qx "sonarqube"; then
  echo "Container 'sonarqube' chua chay. Hay chay lenh docker run o muc 2."
  exit 1
fi

# 2. API trang thai tra ve UP
if ! curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; then
  echo "SonarQube chua o trang thai UP. Hay cho vong lap o muc 3 bao san sang."
  exit 1
fi

# 3. Mat khau admin da duoc doi
if ! curl -s -u admin:AdminSecurePass123 http://localhost:9000/api/authentication/validate | grep -q '"valid":true'; then
  echo "Chua doi mat khau admin sang AdminSecurePass123."
  exit 1
fi

echo "Buoc 1 hoan thanh"
exit 0
