#!/bin/bash

TARGET_IMAGE="custom-web:1.0"
SOURCE_IMAGE="nginx:alpine"

# 1. Kiem tra image nguon ton tai
if ! docker image inspect "$SOURCE_IMAGE" > /dev/null 2>&1; then
    echo "[ERROR] Image '$SOURCE_IMAGE' chua duoc keo ve may. Hay chay lenh: docker pull $SOURCE_IMAGE"
    exit 1
fi

# 2. Kiem tra image tag moi ton tai
if ! docker image inspect "$TARGET_IMAGE" > /dev/null 2>&1; then
    echo "[ERROR] Chua tim thay image '$TARGET_IMAGE'. Hay dung lenh 'docker tag $SOURCE_IMAGE $TARGET_IMAGE' de gan tag."
    exit 1
fi

# 3. Kiem tra Image ID cua 2 tag phai trung khop
ID_TARGET=$(docker image inspect -f '{{.Id}}' "$TARGET_IMAGE" 2>/dev/null)
ID_SOURCE=$(docker image inspect -f '{{.Id}}' "$SOURCE_IMAGE" 2>/dev/null)

if [ "$ID_TARGET" != "$ID_SOURCE" ]; then
    echo "[ERROR] Image '$TARGET_IMAGE' co ID khong trung voi '$SOURCE_IMAGE'."
    exit 1
fi

echo "[SUCCESS] Quan tri Docker Image va gan tag thanh cong!"
echo "Image '$TARGET_IMAGE' da duoc tao va tham chieu chinh xac toi '$SOURCE_IMAGE' (ID: ${ID_TARGET:0:19}...)"
exit 0
