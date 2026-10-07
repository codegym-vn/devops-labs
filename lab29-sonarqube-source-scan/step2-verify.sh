#!/bin/bash
set -e

# 1. Kiem tra du an express-api-service tren SonarQube
PROJECT_EXISTS=$(curl -u admin:AdminSecurePass123 -s "http://localhost:9000/api/projects/search?projects=express-api-service" | jq -r '.components | length' 2>/dev/null || echo "0")
if [ "$PROJECT_EXISTS" -lt 1 ]; then
  echo "Loi: Du an 'express-api-service' chua duoc tao tren SonarQube!"
  exit 1
fi

# 2. Kiem tra tep sonar-token.txt
if [ ! -f /root/sonarqube-lab/sonar-token.txt ]; then
  echo "Loi: Tep /root/sonarqube-lab/sonar-token.txt khong ton tai!"
  exit 1
fi

TOKEN=$(cat /root/sonarqube-lab/sonar-token.txt | tr -d '[:space:]')
if [ -z "$TOKEN" ] || [ ${#TOKEN} -lt 15 ]; then
  echo "Loi: Token trong tep /root/sonarqube-lab/sonar-token.txt khong hop le!"
  exit 1
fi

echo "Du an da duoc tao va Analysis Token da duoc ghi nhan!"
exit 0
