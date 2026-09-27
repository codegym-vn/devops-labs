#!/bin/bash
# background.sh — Lab 12: Cloud VPC + VM + Security Groups
# Cài các tool cần thiết (Docker + UFW đã có sẵn trên Killercoda Ubuntu)

apt-get update -y > /dev/null 2>&1
apt-get install -y netcat-openbsd curl ufw > /dev/null 2>&1

# Kéo sẵn nginx:alpine image
docker pull nginx:alpine > /dev/null 2>&1 &
docker pull alpine > /dev/null 2>&1 &

# Cấu hình UFW mặc định
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow ssh > /dev/null 2>&1  # Giữ SSH để không bị lock out

touch /tmp/.lab_ready
