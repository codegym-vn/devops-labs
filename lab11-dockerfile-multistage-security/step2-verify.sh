#!/usr/bin/env bash
set -e

# 1. Kiem tra Dockerfile.multistage
if [ ! -f /root/app/Dockerfile.multistage ]; then
    echo "[ERROR] File '/root/app/Dockerfile.multistage' khong ton tai."
    echo "Goi y: Hay tao file Dockerfile.multistage voi 2 stage (builder va runtime)."
    exit 1
fi

if ! grep -qi "as\s\+builder" /root/app/Dockerfile.multistage; then
    echo "[ERROR] Dockerfile.multistage chua dinh nghia stage builder (vi du: 'FROM golang:1.22-alpine AS builder')."
    exit 1
fi

if ! grep -qi "copy\s\+--from=builder" /root/app/Dockerfile.multistage; then
    echo "[ERROR] Dockerfile.multistage chua su dung chi thi 'COPY --from=builder'."
    exit 1
fi

# 2. Kiem tra image multistage-app:1.0
if ! docker image inspect multistage-app:1.0 > /dev/null 2>&1; then
    echo "[ERROR] Docker Image 'multistage-app:1.0' chua duoc build."
    echo "Goi y: Chay 'docker build -f Dockerfile.multistage -t multistage-app:1.0 .' tai /root/app."
    exit 1
fi

# 3. Kiem tra kich thuoc image (phai duoi 50MB)
IMAGE_SIZE_BYTES=$(docker inspect -f '{{.Size}}' multistage-app:1.0 2>/dev/null || echo "999999999")
MAX_ALLOWED_BYTES=$((50 * 1024 * 1024)) # 50 MB

if [ "$IMAGE_SIZE_BYTES" -gt "$MAX_ALLOWED_BYTES" ]; then
    SIZE_MB=$((IMAGE_SIZE_BYTES / 1024 / 1024))
    echo "[ERROR] Kich thuoc image 'multistage-app:1.0' qua lon (${SIZE_MB}MB > 50MB)."
    echo "Goi y: Hay chac chan ban da dung base image runtime nhe nhu 'alpine:3.19' va chi copy file nhi phan tu stage builder."
    exit 1
fi

# 4. Kiem tra hoat dong cua container tu image multistage-app:1.0
CID=$(docker run -d -p 18082:8080 multistage-app:1.0 2>/dev/null || echo "")
if [ -z "$CID" ]; then
    echo "[ERROR] Khong the khoi chay container tu image 'multistage-app:1.0'."
    exit 1
fi

sleep 1
HEALTH=$(curl -s --max-time 3 http://localhost:18082/healthz || echo "")
docker rm -f "$CID" > /dev/null 2>&1 || true

if ! echo "$HEALTH" | grep -q '"status":"ok"'; then
    echo "[ERROR] Container chay tu 'multistage-app:1.0' khong phan hoi HTTP 200 tren endpoint /healthz."
    exit 1
fi

echo "[SUCCESS] Dockerfile multi-stage duoc cau hinh chuan xac, dung luong image dat duoi 50MB va ung dung hoat dong tot!"
exit 0
