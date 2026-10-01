#!/bin/bash

# Cập nhật và cài đặt các công cụ bổ trợ cho bài lab
apt-get update -y > /dev/null 2>&1
apt-get install -y tree curl > /dev/null 2>&1

# Dọn dẹp các tệp tạm nếu có
rm -f /tmp/system_identity.txt /tmp/nav_checkpoint.txt /tmp/.nav_reached > /dev/null 2>&1
rm -rf /root/devops-workspace > /dev/null 2>&1

# Đánh dấu môi trường đã sẵn sàng
touch /tmp/.lab_ready
