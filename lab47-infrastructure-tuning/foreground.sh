#!/bin/bash
echo "Dang khoi tao Nginx Reverse Proxy, Backend Service va moi truong Lab 47..."
WAIT_SEC=0
while [ ! -f /tmp/background-finished ] && [ $WAIT_SEC -lt 35 ]; do
  sleep 1
  WAIT_SEC=$((WAIT_SEC + 1))
done
clear
echo "================================================================================"
echo "  LAB 47: TOI UU HOA HA TANG & HE DIEU HANH (NGINX & KERNEL TUNING)             "
echo "  Moi truong: Ubuntu Linux | Nginx: Port 80 | Backend App: Port 8080           "
echo "================================================================================"
echo "  Thong tin he thong thuc hanh:                                                 "
echo "    - Nginx Reverse Proxy: http://localhost:80/api/data                        "
echo "    - Backend App:         http://localhost:8080/health                        "
echo "    - Thu muc du an:       /root/infra-opt-lab                                 "
echo "    - Tep cau hinh Nginx:  /root/infra-opt-lab/nginx/nginx.conf                "
echo "    - Lenh nap lai Nginx:  nginx-reload                                        "
echo "================================================================================"
echo "  Chuyen vao thu muc du an va thuc hien cac yeu cau tai Step 1.                "
echo "================================================================================"
cd /root/infra-opt-lab
