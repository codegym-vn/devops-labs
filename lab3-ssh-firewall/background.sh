#!/bin/bash

# Cap nhat va cai dat cac cong cu can thiet trong nen
apt-get update -y > /dev/null 2>&1
apt-get install -y openssh-server ufw netcat-openbsd curl python3 > /dev/null 2>&1

# Dam bao SSH dang chay
systemctl enable ssh > /dev/null 2>&1
systemctl start ssh > /dev/null 2>&1

# Tao thu muc .ssh cho root neu chua co
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Danh dau moi truong da chuan bi xong
touch /tmp/.lab_ready
