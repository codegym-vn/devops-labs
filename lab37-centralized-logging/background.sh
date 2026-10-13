#!/bin/bash
# Khoi tao moi truong lab Centralized Logging

mkdir -p /root/centralized-logging-lab
mkdir -p /var/log/apps

# 1. Tao file log ban dau cua Order API (JSON)
cat << 'EOF' > /var/log/apps/order-api.log
{"timestamp":"2026-10-13T09:00:01Z","level":"info","service":"order-api","req_id":"req_1001","message":"User initialized checkout","user_id":"usr_441","amount":1500}
{"timestamp":"2026-10-13T09:00:02Z","level":"info","service":"order-api","req_id":"req_1001","message":"Payment verified via Stripe","user_id":"usr_441","amount":1500}
{"timestamp":"2026-10-13T09:00:03Z","level":"info","service":"order-api","req_id":"req_1002","message":"Order created in database","user_id":"usr_582","amount":95}
EOF

# 2. Tao file log ban dau cua Nginx Gateway (Combined log text)
cat << 'EOF' > /var/log/apps/nginx-access.log
192.168.1.50 - - [13/Oct/2026:09:00:01 +0000] "POST /api/checkout HTTP/1.1" 200 450 "https://shop.example.com" "Mozilla/5.0"
192.168.1.51 - - [13/Oct/2026:09:00:03 +0000] "POST /api/orders HTTP/1.1" 201 128 "https://shop.example.com" "Mozilla/5.0"
192.168.1.52 - - [13/Oct/2026:09:00:05 +0000] "GET /health HTTP/1.1" 200 24 "-" "HealthChecker/1.0"
EOF

# 3. Pre-pull docker images ngam
docker pull fluent/fluent-bit:2.2 > /dev/null 2>&1 &
docker pull grafana/loki:2.9.2 > /dev/null 2>&1 &

touch /tmp/background-finished
