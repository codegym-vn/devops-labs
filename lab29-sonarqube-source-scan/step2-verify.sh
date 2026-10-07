#!/bin/bash

# 1. Du an express-api-service ton tai
if ! curl -s -u admin:AdminSecurePass123 "http://localhost:9000/api/projects/search?projects=express-api-service" | grep -q '"key":"express-api-service"'; then
  echo "Du an 'express-api-service' chua duoc tao tren SonarQube."
  exit 1
fi

# 2. Tep token ton tai va hop le
TOKEN_FILE=/root/sonarqube-lab/sonar-token.txt
if [ ! -s "$TOKEN_FILE" ]; then
  echo "Tep $TOKEN_FILE chua ton tai hoac rong."
  exit 1
fi

TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
if [ "$TOKEN" = "null" ] || [ ${#TOKEN} -lt 20 ]; then
  echo "Token trong $TOKEN_FILE khong hop le. Hay chay lai lenh sinh token."
  exit 1
fi

# 3. Token xac thuc duoc voi server
if ! curl -s -u "$TOKEN:" http://localhost:9000/api/authentication/validate | grep -q '"valid":true'; then
  echo "Token khong xac thuc duoc voi SonarQube. Hay sinh lai token."
  exit 1
fi

echo "Buoc 2 hoan thanh"
exit 0
