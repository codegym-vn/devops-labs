#!/usr/bin/env bash
set -e

# 1. Kiem tra file .dockerignore
if [ ! -f /root/app/.dockerignore ]; then
    echo "[ERROR] File '/root/app/.dockerignore' khong ton tai."
    echo "Goi y: Hay tao file /root/app/.dockerignore voi noi dung loai tru .git va cac file thua."
    exit 1
fi

if ! grep -q "\.git" /root/app/.dockerignore; then
    echo "[ERROR] File '/root/app/.dockerignore' chua co chi thi loai tru '.git'."
    exit 1
fi

# 2. Kiem tra Dockerfile.cached va thu tu chi thi
if [ ! -f /root/app/Dockerfile.cached ]; then
    echo "[ERROR] File '/root/app/Dockerfile.cached' khong ton tai."
    exit 1
fi

# Kiem tra xem COPY go.mod co xuat hien truoc COPY main.go hay COPY . khong
LINE_MOD=$(grep -n "COPY.*go\.mod" /root/app/Dockerfile.cached | cut -d: -f1 | head -n1 || echo "")
LINE_CODE=$(grep -n "COPY.*main\.go" /root/app/Dockerfile.cached | cut -d: -f1 | head -n1 || echo "")
if [ -z "$LINE_CODE" ]; then
    LINE_CODE=$(grep -n "COPY\s\+\.\s\+\." /root/app/Dockerfile.cached | cut -d: -f1 | head -n1 || echo "")
fi

if [ -z "$LINE_MOD" ]; then
    echo "[ERROR] Khong tim thay chi thi 'COPY go.mod' trong Dockerfile.cached."
    exit 1
fi

if [ -n "$LINE_CODE" ] && [ "$LINE_MOD" -gt "$LINE_CODE" ]; then
    echo "[ERROR] Chi thi 'COPY go.mod' phai duoc dat TRUOC 'COPY main.go' de dam bao toi uu cache."
    exit 1
fi

# 3. Kiem tra image cached-app:1.0
if ! docker image inspect cached-app:1.0 > /dev/null 2>&1; then
    echo "[ERROR] Docker Image 'cached-app:1.0' chua duoc build thanh cong."
    echo "Goi y: Chay 'docker build -f Dockerfile.cached -t cached-app:1.0 .' tai /root/app."
    exit 1
fi

# 4. Kiem tra tinh hoat dong cua ung dung tu image cached-app:1.0
CID=$(docker run -d -p 18081:8080 cached-app:1.0 2>/dev/null || echo "")
if [ -z "$CID" ]; then
    echo "[ERROR] Khong the khoi chay container tu image 'cached-app:1.0'."
    exit 1
fi

sleep 1
HEALTH=$(curl -s --max-time 3 http://localhost:18081/healthz || echo "")
docker rm -f "$CID" > /dev/null 2>&1 || true

if ! echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "[ERROR] Container chay tu 'cached-app:1.0' khong tra ve HTTP 200 tren endpoint /healthz."
    exit 1
fi

echo "[SUCCESS] File .dockerignore va Dockerfile.cached dat chuan toi uu layer caching, image cached-app:1.0 hoat dong tot!"
exit 0
