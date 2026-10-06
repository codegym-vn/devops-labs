#!/usr/bin/env bash

APP_DIR="/root/cicd-app"
WF=".github/workflows/ci.yml"
REGISTRY="http://localhost:5000"

cd "$APP_DIR" 2> /dev/null || { echo "[ERROR] Khong tim thay thu muc $APP_DIR."; exit 1; }

# 1. Workflow tren main co job package dung cau hinh
WF_CONTENT=$(git show "main:$WF" 2> /dev/null)
if [ -z "$WF_CONTENT" ]; then
  echo "[ERROR] Khong doc duoc $WF tren nhanh 'main'."
  exit 1
fi

check() {
  if ! echo "$WF_CONTENT" | grep -Eq "$1"; then
    echo "[ERROR] $2"
    exit 1
  fi
}
check '^[[:space:]]+package:' "Workflow chua co job id 'package'."
if ! echo "$WF_CONTENT" | grep -A2 'needs:' | grep -q 'test'; then
  echo "[ERROR] Job 'package' chua khai bao 'needs: test'."
  exit 1
fi
check 'refs/heads/main' "Job 'package' chua co dieu kien chi chay tren nhanh main (if: github.ref == 'refs/heads/main')."
check 'GITHUB_SHA' "Chua dung bien GITHUB_SHA de tinh tag image."
check 'docker build' "Job 'package' chua co lenh 'docker build'."
check 'docker push' "Job 'package' chua co lenh 'docker push'."
check 'actions/upload-artifact@' "Job 'test' chua co step 'actions/upload-artifact@v4'."

# 2. Registry hoat dong
TAGS=$(curl -s --max-time 5 "$REGISTRY/v2/cicd-app/tags/list")
if [ -z "$TAGS" ] || ! echo "$TAGS" | grep -q '"tags"'; then
  echo "[ERROR] Registry chua co repository 'cicd-app'. Ket qua: ${TAGS:-<rong>}"
  echo "Goi y: Chay 'act push' tren nhanh main de job package push image."
  exit 1
fi

# 3. Tag SHA khop voi commit HEAD cua main va co tag latest
SHORT_SHA=$(git rev-parse main | cut -c1-7)
if ! echo "$TAGS" | grep -q "\"sha-${SHORT_SHA}\""; then
  echo "[ERROR] Registry chua co tag 'sha-${SHORT_SHA}' ung voi commit HEAD cua main."
  echo "Tags hien co: $TAGS"
  echo "Goi y: Hay commit thay doi TRUOC roi moi chay 'act push' de GITHUB_SHA trung voi HEAD."
  exit 1
fi

if ! echo "$TAGS" | grep -q '"latest"'; then
  echo "[ERROR] Registry chua co tag 'latest' cho cicd-app."
  exit 1
fi

# 4. Artifact coverage da duoc luu
if [ -z "$(find /tmp/artifacts -type f 2> /dev/null | head -1)" ]; then
  echo "[ERROR] Chua tim thay artifact nao trong /tmp/artifacts."
  echo "Goi y: Kiem tra step 'Upload coverage report' trong job test."
  exit 1
fi

echo "[SUCCESS] Pipeline da dong goi image 'localhost:5000/cicd-app:sha-${SHORT_SHA}' + 'latest' va luu artifact coverage thanh cong!"
exit 0
