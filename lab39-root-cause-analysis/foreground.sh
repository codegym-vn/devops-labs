#!/bin/bash
echo "Dang khoi tao he thong Microservices va tai hien hien truong su co, vui long cho trong giay lat..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 40 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "================================================================================"
echo "  🚨 P1 INCIDENT ALERT: CHECKOUT SERVICE DEGRADATION                            "
echo "  Thoi gian: 02:15 AM | Mức độ nghiêm trọng: P1 (Critical Outage)              "
echo "================================================================================"
echo "  Trieu chung: Khach hang khong the thanh toan don hang tren toan he thong.    "
echo "  Cong cu Observability san sang:                                              "
echo "    - Jaeger UI: http://localhost:16686 (Tracing)                              "
echo "    - Loki API:  http://localhost:3100 (Centralized Logs)                      "
echo "    - API Gateway: http://localhost:80/api/checkout                            "
echo "================================================================================"
echo "  Nhiem vu cua ban: Khong doan mo! Su dung Tracing va Centralized Logging de   "
echo "  co lap thu pham, tim nguyen nhan goc re (RCA) va tien hanh Hotfix cuu he thong."
echo "================================================================================"
cd /root/incident-lab
