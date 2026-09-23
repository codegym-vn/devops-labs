#!/bin/bash

# Cap nhat va cai dat cac cong cu can thiet trong nen
apt-get update -y > /dev/null 2>&1
apt-get install -y nginx openssl curl > /dev/null 2>&1

# Tat Nginx mac dinh, step3 se tu cau hinh va bat
systemctl stop nginx 2>/dev/null

# Danh dau moi truong da chuan bi xong
touch /tmp/.lab_ready
