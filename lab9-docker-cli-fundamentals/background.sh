#!/bin/bash

# Tao thu muc chua file mau
mkdir -p /root/sample-site

# Tao file HTML mau cho Step 2 (docker cp)
cat << 'EOF' > /root/sample-site/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>DevOps Custom Web</title>
    <style>
        body { font-family: sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding-top: 50px; }
        h1 { color: #38bdf8; }
        .badge { background: #0284c7; padding: 5px 12px; border-radius: 4px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Chuc Mung! Trang Web Da Duoc Cap Nhat Qua Docker CP</h1>
    <p class="badge">DEVOPS DOCKER FUNDAMENTALS - LAB 9</p>
    <p>File nay duoc sao chep truc tiep tu host vao container dang chay.</p>
</body>
</html>
EOF

# Tai truoc cac image co ban trong background
docker pull alpine:3.19 > /dev/null 2>&1 &
docker pull nginx:alpine > /dev/null 2>&1 &

# Danh dau moi truong da san sang
touch /tmp/.lab_ready
