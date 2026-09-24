#!/usr/bin/env bash
set -e

# 1. Kiem tra image devops-toolbox:v1.0 co ton tai khong
IMAGE_EXISTS=$(docker images -q devops-toolbox:v1.0 2>/dev/null || echo "")
if [ -z "$IMAGE_EXISTS" ]; then
    echo "[ERROR] Docker Image 'devops-toolbox:v1.0' khong ton tai."
    echo "Goi y: Hay chay 'docker commit -m \"Add curl network tool\" -a \"DevOps Student\" tool-builder devops-toolbox:v1.0'."
    exit 1
fi

# 2. Kiem tra cong cu curl ben trong image devops-toolbox:v1.0
CURL_TEST=$(docker run --rm devops-toolbox:v1.0 curl --version 2>/dev/null || echo "")
if ! echo "$CURL_TEST" | grep -q "curl"; then
    echo "[ERROR] Image 'devops-toolbox:v1.0' da duoc tao nhung khong thuc thi duoc lenh 'curl'."
    echo "Goi y: Hay chac chan ban da chay 'apk add --no-cache curl' ben trong container truoc khi commit."
    exit 1
fi

echo "[SUCCESS] Image 'devops-toolbox:v1.0' ton tai va cong cu curl hoat dong chinh xac!"
exit 0
