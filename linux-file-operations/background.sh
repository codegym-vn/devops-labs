#!/bin/bash

# Cập nhật và cài đặt công cụ cần thiết
apt-get update -y > /dev/null 2>&1
apt-get install -y tree curl > /dev/null 2>&1

# Dọn dẹp môi trường cũ nếu có
rm -rf /root/ecommerce-app /tmp/file-ops-report.txt /tmp/app-service.log > /dev/null 2>&1

# Tạo file log mẫu có 50 dòng phục vụ Bước 3
mkdir -p /var/log/myapp
for i in $(seq 1 50); do
    TIMESTAMP=$(date -d "-$((50 - i)) minutes" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")
    if [ $((i % 10)) -eq 0 ]; then
        echo "[$TIMESTAMP] [ERROR] Payment gateway timeout on transaction TX-$((1000 + i))" >> /var/log/myapp/service.log
    elif [ $((i % 3)) -eq 0 ]; then
        echo "[$TIMESTAMP] [WARN] High memory consumption detected on worker thread #$((i % 4))" >> /var/log/myapp/service.log
    else
        echo "[$TIMESTAMP] [INFO] HTTP GET /api/v1/products status=200 response_time=$((15 + i))ms" >> /var/log/myapp/service.log
    fi
done

# Đánh dấu môi trường sẵn sàng
touch /tmp/.lab_ready
