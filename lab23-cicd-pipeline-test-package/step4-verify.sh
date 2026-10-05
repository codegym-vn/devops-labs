#!/usr/bin/env bash

APP_DIR="/root/cicd-app"
WF=".github/workflows/ci.yml"
REGISTRY="http://localhost:5000"
CONTAINER="cicd-app-smoke"

cd "$APP_DIR" 2> /dev/null || { echo "[ERROR] Khong tim thay thu muc $APP_DIR."; exit 1; }

# 1. Workflow tren main co step smoke test
WF_CONTENT=$(git show "main:$WF" 2> /dev/null)
if ! echo "$WF_CONTENT" | grep -q "$CONTAINER"; then
  echo "[ERROR] Workflow tren 'main' chua co step smoke test chay container '$CONTAINER'."
  exit 1
fi
if ! echo "$WF_CONTENT" | grep -Eq 'curl.*healthz'; then
  echo "[ERROR] Step smoke test chua goi endpoint /healthz bang curl."
  exit 1
fi

# 2. Ma nguon tren main da nang phien ban 1.1.0
if ! git show main:main.go | grep -Eq 'Version[[:space:]]*=[[:space:]]*"1\.1\.0"'; then
  echo "[ERROR] Hang so Version trong main.go tren nhanh 'main' chua phai \"1.1.0\"."
  exit 1
fi

# 3. Container smoke test dang chay dung image cua commit HEAD
SHORT_SHA=$(git rev-parse main | cut -c1-7)
EXPECTED_IMAGE="localhost:5000/cicd-app:sha-${SHORT_SHA}"

STATE=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2> /dev/null)
if [ "$STATE" != "true" ]; then
  echo "[ERROR] Container '$CONTAINER' khong ton tai hoac khong o trang thai Running."
  echo "Goi y: Commit thay doi roi chay lai 'act push' tren nhanh main."
  exit 1
fi

IMAGE=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")
if [ "$IMAGE" != "$EXPECTED_IMAGE" ]; then
  echo "[ERROR] Container '$CONTAINER' dang chay image '$IMAGE', mong doi '$EXPECTED_IMAGE'."
  echo "Goi y: Hay commit TRUOC roi moi chay 'act push' de tag trung voi HEAD cua main."
  exit 1
fi

# 4. Endpoint tra ve dung phien ban moi
HEALTH=$(curl -s --max-time 5 http://localhost:8088/healthz)
if ! echo "$HEALTH" | grep -q '"status":"ok"' || ! echo "$HEALTH" | grep -q '"version":"1.1.0"'; then
  echo "[ERROR] http://localhost:8088/healthz chua tra ve status ok va version 1.1.0. Ket qua: ${HEALTH:-<rong>}"
  exit 1
fi

# 5. Registry luu lich su it nhat 2 ban phat hanh (phuc vu rollback)
SHA_COUNT=$(curl -s --max-time 5 "$REGISTRY/v2/cicd-app/tags/list" | grep -o '"sha-[0-9a-f]*"' | sort -u | wc -l)
if [ "$SHA_COUNT" -lt 2 ]; then
  echo "[ERROR] Registry moi co $SHA_COUNT tag SHA, can it nhat 2 ban (1.0.0 o Buoc 3 va 1.1.0)."
  exit 1
fi

echo "[SUCCESS] Smoke test tu dong hoat dong, phien ban 1.1.0 (sha-${SHORT_SHA}) dang chay va registry luu $SHA_COUNT ban phat hanh san sang rollback!"
exit 0
