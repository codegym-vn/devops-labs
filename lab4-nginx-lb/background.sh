#!/bin/bash

# Cap nhat va cai dat cac cong cu can thiet
apt-get update -y > /dev/null 2>&1
apt-get install -y nginx curl python3 > /dev/null 2>&1

# Tat Nginx mac dinh, step1 se tu cau hinh
systemctl stop nginx 2>/dev/null

# Tao 3 backend gia lap tren port 8001, 8002, 8003
for PORT in 8001 8002 8003; do
    mkdir -p /opt/backend-$PORT
    echo "Response from Backend $PORT" > /opt/backend-$PORT/index.html
    cd /opt/backend-$PORT
    nohup python3 -m http.server $PORT > /dev/null 2>&1 &
done

# Cho backend khoi dong xong
sleep 2

# Danh dau moi truong da san sang
touch /tmp/.lab_ready
