#!/bin/bash
echo "Dang khoi tao moi truong kiem thu tai k6 va Target API, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 30 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "================================================================================"
echo "  LAB 44: XAY DUNG KICH BAN LOAD & STRESS TESTING VOI K6                        "
echo "  Moi truong: Ubuntu Linux | Cong cu: k6 | Target API: Port 8080               "
echo "================================================================================"
echo "  Thong tin moi truong thuc hanh:                                               "
echo "    - Target API:       http://localhost:8080/health                            "
echo "    - API Endpoints:    GET /api/products, POST /api/orders                    "
echo "    - Thu muc lam viec: /root/load-test-lab                                     "
echo "    - Cong cu:          k6 (kiem tra bang lenh: k6 version)                    "
echo "================================================================================"
echo "  Bat dau bang cach chuyen vao thu muc du an va doc huong dan tai Step 1.       "
echo "================================================================================"
cd /root/load-test-lab
