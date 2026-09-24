#!/usr/bin/env bash
set -e

# 1. Kiem tra Dockerfile
if [ ! -f /root/app/Dockerfile ]; then
    echo "[ERROR] File '/root/app/Dockerfile' khong ton tai."
    echo "Goi y: Hay tao file Dockerfile tich hop multi-stage va non-root user."
    exit 1
fi

if ! grep -qi "USER\s\+" /root/app/Dockerfile; then
    echo "[ERROR] Dockerfile chua khai bao chi thi 'USER' de chuyen sang nguoi dung non-root."
    exit 1
fi

# 2. Kiem tra image secure-app:1.0
if ! docker image inspect secure-app:1.0 > /dev/null 2>&1; then
    echo "[ERROR] Docker Image 'secure-app:1.0' chua duoc build."
    echo "Goi y: Chay 'docker build -t secure-app:1.0 .' tai /root/app."
    exit 1
fi

# 3. Kiem tra UID cau hinh trong image
CONFIG_USER=$(docker inspect -f '{{.Config.User}}' secure-app:1.0 2>/dev/null || echo "")
if [ -z "$CONFIG_USER" ] || [ "$CONFIG_USER" = "0" ] || [ "$CONFIG_USER" = "root" ]; then
    echo "[ERROR] Image 'secure-app:1.0' van dang chay duoi quyen root (User config: '$CONFIG_USER')."
    echo "Goi y: Khai bao 'USER 10001:10001' trong Dockerfile."
    exit 1
fi

# 4. Kiem tra container secure-app-container
RUNNING=$(docker inspect -f '{{.State.Running}}' secure-app-container 2>/dev/null || echo "false")
if [ "$RUNNING" != "true" ]; then
    echo "[ERROR] Container 'secure-app-container' khong o trang thai dang chay."
    echo "Goi y: Chay 'docker run -d --name secure-app-container -p 8080:8080 secure-app:1.0'."
    exit 1
fi

# 5. Kiem tra UID thuc te ben trong container
ACTUAL_UID=$(docker exec secure-app-container id -u 2>/dev/null || echo "0")
if [ "$ACTUAL_UID" = "0" ]; then
    echo "[ERROR] Tien trinh trong container 'secure-app-container' dang chay voi UID 0 (root)."
    exit 1
fi

# 6. Kiem tra phan hoi tu API /user
USER_API=$(curl -s --max-time 3 http://localhost:8080/user || echo "")
if ! echo "$USER_API" | grep -q '"is_root":false'; then
    echo "[ERROR] API /user khong tra ve '\"is_root\":false'. Noi dung: $USER_API"
    exit 1
fi

echo "[SUCCESS] Dockerfile chuan Production hoan tat xuat sac! Dung luong toi uu va tien trinh duoc bao ve an toan duoi quyen non-root (UID $ACTUAL_UID)!"
exit 0
