#!/bin/bash

# Cập nhật và cài đặt các công cụ mạng cần thiết trong nền
apt-get update -y > /dev/null 2>&1
apt-get install -y ipcalc iproute2 dnsutils netcat-openbsd curl > /dev/null 2>&1

# Đánh dấu môi trường đã chuẩn bị xong
touch /tmp/.lab_ready
