#!/bin/bash

CONTAINER="data-service"

# 1. Kiem tra container ton tai
if ! docker inspect "$CONTAINER" > /dev/null 2>&1; then
    echo "[ERROR] Container '$CONTAINER' chua duoc tao. Hay khoi chay container theo yeu cau."
    exit 1
fi

# 2. Kiem tra trang thai running
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
if [ "$STATUS" != "running" ]; then
    echo "[ERROR] Container '$CONTAINER' khong o trang thai 'running' (hien tai: $STATUS)."
    exit 1
fi

# 3. Kiem tra gioi han RAM (256MB = 268435456 bytes)
MEM=$(docker inspect -f '{{.HostConfig.Memory}}' "$CONTAINER" 2>/dev/null)
if [ "$MEM" -ne 268435456 ]; then
    echo "[ERROR] Gioi han RAM chua dung (hien tai: $MEM bytes, yeu cau: 256MB / 268435456 bytes)."
    exit 1
fi

# 4. Kiem tra gioi han Memory Swap (256MB = 268435456 bytes)
SWAP=$(docker inspect -f '{{.HostConfig.MemorySwap}}' "$CONTAINER" 2>/dev/null)
if [ "$SWAP" -ne 268435456 ]; then
    echo "[ERROR] Gioi han Swap chua dung (hien tai: $SWAP bytes, yeu cau: 256MB / 268435456 bytes)."
    exit 1
fi

# 5. Kiem tra gioi han CPU (0.5 core = 500000000 NanoCpus)
CPUS=$(docker inspect -f '{{.HostConfig.NanoCpus}}' "$CONTAINER" 2>/dev/null)
if [ "$CPUS" -ne 500000000 ]; then
    echo "[ERROR] Gioi han CPU chua dung (hien tai: $CPUS NanoCpus, yeu cau: 0.5 core / 500000000 NanoCpus)."
    exit 1
fi

# 6. Kiem tra cau hinh Log Rotation (max-size=2m, max-file=3)
MAX_SIZE=$(docker inspect -f '{{index .HostConfig.LogConfig.Config "max-size"}}' "$CONTAINER" 2>/dev/null)
MAX_FILE=$(docker inspect -f '{{index .HostConfig.LogConfig.Config "max-file"}}' "$CONTAINER" 2>/dev/null)

if [ "$MAX_SIZE" != "2m" ] || [ "$MAX_FILE" != "3" ]; then
    echo "[ERROR] Cau hinh Log Rotation chua dung (hien tai: max-size='$MAX_SIZE', max-file='$MAX_FILE')."
    echo "Yeu cau: --log-opt max-size=2m --log-opt max-file=3"
    exit 1
fi

echo "[SUCCESS] Container 'data-service' da duoc thiet lap day du gioi han tai nguyen va xoay vong log:"
echo "CPU: 0.5 core | RAM: 256MB | Swap: 256MB | Log Rotation: max-size=2m, max-file=3"
exit 0
