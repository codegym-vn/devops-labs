#!/usr/bin/env bash
set -e

# 1. Kiem tra container my-web co ton tai va dang chay khong
RUNNING=$(docker inspect -f '{{.State.Running}}' my-web 2>/dev/null || echo "false")
if [ "$RUNNING" != "true" ]; then
    echo "[ERROR] Container 'my-web' khong ton tai hoac khong o trang thai running."
    echo "Goi y: Hay chay 'docker run -d --name my-web -p 8080:80 nginx:alpine'."
    exit 1
fi

# 2. Kiem tra curl toi port 8080
RESPONSE=$(curl -s --max-time 3 http://localhost:8080 || echo "")
if ! echo "$RESPONSE" | grep -q "DevOps Custom Web"; then
    echo "[ERROR] Truy cap http://localhost:8080 khong tim thay noi dung 'DevOps Custom Web'."
    echo "Goi y: Hay kiem tra lenh 'docker cp /root/sample-site/index.html my-web:/usr/share/nginx/html/index.html'."
    exit 1
fi

# 3. Kiem tra docker diff my-web
DIFF_OUTPUT=$(docker diff my-web 2>/dev/null || echo "")
if ! echo "$DIFF_OUTPUT" | grep -q "usr/share/nginx/html"; then
    echo "[ERROR] Khong phat hien thay doi file trong /usr/share/nginx/html tren container 'my-web'."
    exit 1
fi

echo "[SUCCESS] Container 'my-web' dang chay, da sao chep file thanh cong va web tra ve dung noi dung!"
exit 0
