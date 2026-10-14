#!/bin/bash
echo "Dang khoi tao moi truong Lab 46: Catalog Service va Diagnostic Data..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 35 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "================================================================================"
echo "  LAB 46: [CASE STUDY] PHAN TICH BAO CAO & TOI UU TANG UNG DUNG                 "
echo "  Moi truong: Ubuntu Linux | Port: 8080 (Catalog API) | Redis Cache: 6379       "
echo "================================================================================"
echo "  Thong tin he thong thuc hanh:                                                 "
echo "    - Target Catalog API:  http://localhost:8080/health                        "
echo "    - API Endpoint:        http://localhost:8080/api/catalog                   "
echo "    - Thu muc du an:       /root/app-opt-lab                                   "
echo "    - Bao cao chan doan:   /root/app-opt-lab/reports/initial-report.json       "
echo "================================================================================"
echo "  Bat dau bang cach doc bao cao chan doan va khao sat ma nguon tai Step 1.    "
echo "================================================================================"
cd /root/app-opt-lab
