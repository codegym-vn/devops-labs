#!/bin/bash

CONTAINER="web-runtime"

# 1. Kiem tra container ton tai
if ! docker inspect "$CONTAINER" > /dev/null 2>&1; then
    echo "[ERROR] Container '$CONTAINER' chua duoc khoi tao. Hay kiem tra ten container."
    exit 1
fi

# 2. Kiem tra container dang o trang thai running
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
if [ "$STATUS" != "running" ]; then
    echo "[ERROR] Container '$CONTAINER' khong o trang thai 'running' (trang thai hien tai: $STATUS)."
    exit 1
fi

# 3. Kiem tra Restart Policy
RESTART_POLICY=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$CONTAINER" 2>/dev/null)
if [ "$RESTART_POLICY" != "unless-stopped" ]; then
    echo "[ERROR] Chinh sach restart chua chinh xac (hien tai: '$RESTART_POLICY', yeu cau: 'unless-stopped')."
    exit 1
fi

# 4. Kiem tra Port Mapping (8080:8080)
PORT_CHECK=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "8080/tcp") 0).HostPort}}' "$CONTAINER" 2>/dev/null)
if [ "$PORT_CHECK" != "8080" ]; then
    echo "[ERROR] Port mapping chua dung. Cong host 8080 phai duoc anh xa vao cong container 8080."
    exit 1
fi

# 5. Kiem tra bien moi truong tu file .env.app
ENV_OUTPUT=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" 2>/dev/null)
if ! echo "$ENV_OUTPUT" | grep -q "APP_ENV=production" || ! echo "$ENV_OUTPUT" | grep -q "APP_PORT=8080"; then
    echo "[ERROR] Container thieu cac bien moi truong tu /root/app/.env.app. Hay dung co --env-file /root/app/.env.app."
    exit 1
fi

echo "[SUCCESS] Container 'web-runtime' da duoc cau hinh day du tham so runtime:"
echo "Trang thai: $STATUS | Restart: $RESTART_POLICY | Port: 8080->8080 | Env: APP_ENV, APP_PORT OK"
exit 0
