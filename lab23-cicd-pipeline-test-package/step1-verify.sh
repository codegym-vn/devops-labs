#!/usr/bin/env bash

APP_DIR="/root/cicd-app"
WF=".github/workflows/ci.yml"
LOG="/root/ci-logs/step1.log"

cd "$APP_DIR" 2> /dev/null || { echo "[ERROR] Khong tim thay thu muc $APP_DIR."; exit 1; }

# 1. Workflow ton tai va da duoc commit vao nhanh main
if [ ! -f "$WF" ]; then
  echo "[ERROR] Chua tim thay file $APP_DIR/$WF."
  exit 1
fi

if ! CONTENT=$(git show "main:$WF" 2> /dev/null); then
  echo "[ERROR] File $WF chua duoc commit vao nhanh 'main'."
  echo "Goi y: git add $WF && git commit -m 'ci: them workflow kiem thu tu dong'"
  exit 1
fi

# 2. YAML hop le (neu he thong co PyYAML)
if python3 -c "import yaml" 2> /dev/null; then
  if ! python3 -c "import yaml,sys; yaml.safe_load(open('$WF'))" 2> /dev/null; then
    echo "[ERROR] File $WF khong phai YAML hop le. Hay kiem tra lai thut le (indent) bang dau cach."
    exit 1
  fi
fi

# 3. Cac thanh phan bat buoc
check() {
  if ! echo "$CONTENT" | grep -Eq "$1"; then
    echo "[ERROR] $2"
    exit 1
  fi
}
check '^on:|^"on":|^true:' "Workflow chua khai bao trigger 'on:'."
check 'push' "Workflow chua co trigger 'push'."
check 'feature' "Trigger 'push' can khai bao ca nhanh 'feature/**'."
check '^[[:space:]]+test:' "Chua tim thay job co id 'test'."
check 'actions/checkout@' "Job 'test' chua co step 'actions/checkout@v4'."
check 'actions/setup-go@' "Job 'test' chua co step 'actions/setup-go@v5'."
check 'gofmt -l' "Chua co step kiem tra format bang 'gofmt -l'."
check 'go vet' "Chua co step phan tich tinh 'go vet ./...'."
check 'go test' "Chua co step chay unit test 'go test'."
check 'coverprofile' "Lenh 'go test' can co co '-coverprofile=coverage.out'."

# 4. Pipeline da chay thanh cong
if [ ! -f "$LOG" ]; then
  echo "[ERROR] Chua tim thay log $LOG."
  echo "Goi y: act push -j test 2>&1 | tee $LOG"
  exit 1
fi

if grep -q "Job failed" "$LOG" || ! grep -q "Job succeeded" "$LOG"; then
  echo "[ERROR] Pipeline trong $LOG chua chay thanh cong (khong thay 'Job succeeded')."
  echo "Goi y: Doc log de tim step loi, sua va chay lai lenh act."
  exit 1
fi

echo "[SUCCESS] Workflow CI hop le da duoc commit vao main va pipeline job 'test' chay thanh cong!"
exit 0
