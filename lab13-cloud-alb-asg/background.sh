#!/bin/bash
# background.sh — Lab 13: Load Balancer & Auto Scaling

apt-get update -y > /dev/null 2>&1
apt-get install -y nginx netcat-openbsd curl > /dev/null 2>&1

systemctl enable nginx > /dev/null 2>&1
systemctl start nginx > /dev/null 2>&1

# Kéo sẵn image
docker pull nginx:alpine > /dev/null 2>&1 &

touch /tmp/.lab_ready
