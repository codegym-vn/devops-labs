#!/bin/bash
set -e

# 1. Kiem tra tep sonar-project.properties
if [ ! -f /root/sonarqube-lab/sonar-project.properties ]; then
  echo "Loi: Tep /root/sonarqube-lab/sonar-project.properties khong ton tai!"
  exit 1
fi

if ! grep -q "sonar.projectKey=express-api-service" /root/sonarqube-lab/sonar-project.properties; then
  echo "Loi: sonar-project.properties chua cau hinh dung projectKey 'express-api-service'!"
  exit 1
fi

# 2. Kiem tra tep ket qua scan .scannerwork/report-task.txt
if [ ! -f /root/sonarqube-lab/.scannerwork/report-task.txt ]; then
  echo "Loi: Thu muc .scannerwork/report-task.txt chua xuat hien, SonarScanner chua chay thanh cong!"
  exit 1
fi

if ! grep -q "express-api-service" /root/sonarqube-lab/.scannerwork/report-task.txt; then
  echo "Loi: Bao cao trong report-task.txt khong khop voi projectKey 'express-api-service'!"
  exit 1
fi

echo "SonarScanner da thuc thi thanh cong va gui bao cao ve may chu SonarQube!"
exit 0
