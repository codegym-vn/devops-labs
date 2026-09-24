#!/bin/bash

CONTAINER="graceful-app"

# 1. Kiem tra container ton tai
if ! docker inspect "$CONTAINER" > /dev/null 2>&1; then
    echo "[ERROR] Container '$CONTAINER' chua duoc tao. Hay khoi chay container theo yeu cau."
    exit 1
fi

# 2. Kiem tra container da dung (exited)
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
if [ "$STATUS" != "exited" ]; then
    echo "[ERROR] Container '$CONTAINER' chua duoc dung (trang thai hien tai: '$STATUS')."
    echo "Hay chay lenh: docker stop -t 10 $CONTAINER"
    exit 1
fi

# 3. Kiem tra ExitCode (phai bang 0, khong duoc bang 137 do SIGKILL)
EXIT_CODE=$(docker inspect -f '{{.State.ExitCode}}' "$CONTAINER" 2>/dev/null)
if [ "$EXIT_CODE" -ne 0 ]; then
    echo "[ERROR] Container khong tat an toan (ExitCode hien tai: $EXIT_CODE)."
    if [ "$EXIT_CODE" -eq 137 ]; then
        echo "Loi: Container bi ep chet boi SIGKILL (Timeout hoac ung dung khong bat duoc SIGTERM)."
    fi
    exit 1
fi

# 4. Kiem tra nhat ky ghi nhan tien trinh Graceful Shutdown
LOGS=$(docker logs "$CONTAINER" 2>&1)
if ! echo "$LOGS" | grep -qi "Graceful Shutdown" || ! echo "$LOGS" | grep -qi "Graceful exit"; then
    echo "[ERROR] Nhat ky container khong ghi nhan quy trinh Graceful Shutdown."
    exit 1
fi

echo "[SUCCESS] Kiem thu Graceful Shutdown thanh cong hoan toan!"
echo "Container '$CONTAINER' da bat tin hieu SIGTERM thanh cong, xu ly tron ven ket noi dang chay va thoat an toan voi ExitCode: 0."
exit 0
