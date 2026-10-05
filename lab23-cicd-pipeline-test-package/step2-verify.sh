#!/usr/bin/env bash

APP_DIR="/root/cicd-app"
WF=".github/workflows/ci.yml"
FAIL_LOG="/root/ci-logs/step2-fail.log"
PASS_LOG="/root/ci-logs/step2-pass.log"
export PATH="$PATH:/usr/local/go/bin"
export HOME="${HOME:-/root}"
export GOCACHE="${GOCACHE:-/tmp/go-build-verify}"

cd "$APP_DIR" 2> /dev/null || { echo "[ERROR] Khong tim thay thu muc $APP_DIR."; exit 1; }

# 1. Nhanh feature/discount da duoc merge vao main
if ! git show main:pricing.go > /dev/null 2>&1; then
  echo "[ERROR] Nhanh 'main' chua co file pricing.go."
  echo "Goi y: git checkout main && git merge --no-ff feature/discount"
  exit 1
fi

# 2. Kiem tra ma nguon tren main trong thu muc tam (khong phu thuoc working tree)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
git archive main | tar -x -C "$TMP_DIR"

UNFORMATTED=$(cd "$TMP_DIR" && gofmt -l .)
if [ -n "$UNFORMATTED" ]; then
  echo "[ERROR] Cac file tren 'main' chua dung chuan gofmt: $UNFORMATTED"
  exit 1
fi

if ! (cd "$TMP_DIR" && go test ./... > /dev/null 2>&1); then
  echo "[ERROR] Unit test tren nhanh 'main' van that bai."
  echo "Goi y: Sua cong thuc trong ApplyDiscount de tra ve gia SAU khi giam."
  exit 1
fi

# 3. File test khong bi sua de 'ep' pipeline xanh
if ! git show main:pricing_test.go | grep -q '100000, 20, 80000'; then
  echo "[ERROR] pricing_test.go da bi thay doi ky vong. Hay sua code, khong sua test."
  exit 1
fi

# 4. Cong chat luong coverage trong workflow tren main
WF_CONTENT=$(git show "main:$WF" 2> /dev/null)
if ! echo "$WF_CONTENT" | grep -q 'go tool cover'; then
  echo "[ERROR] Workflow tren 'main' chua co step dung 'go tool cover' de kiem tra coverage."
  exit 1
fi
if ! echo "$WF_CONTENT" | grep -q '70'; then
  echo "[ERROR] Workflow chua khai bao nguong coverage 70%."
  exit 1
fi

# 5. Lich su pipeline: da tung do va da xanh
if [ ! -f "$FAIL_LOG" ] || ! grep -q "Job failed" "$FAIL_LOG"; then
  echo "[ERROR] Chua tim thay log pipeline that bai tai $FAIL_LOG (can co 'Job failed')."
  echo "Goi y: Tren nhanh feature/discount chua sua, chay: act push -j test 2>&1 | tee $FAIL_LOG"
  exit 1
fi

if [ ! -f "$PASS_LOG" ] || grep -q "Job failed" "$PASS_LOG" || ! grep -q "Job succeeded" "$PASS_LOG"; then
  echo "[ERROR] Log $PASS_LOG chua the hien pipeline chay thanh cong."
  echo "Goi y: Sau khi sua loi, chay: act push -j test 2>&1 | tee $PASS_LOG"
  exit 1
fi

if ! grep -qi 'coverage' "$PASS_LOG"; then
  echo "[ERROR] Log $PASS_LOG khong cho thay step Coverage gate da chay."
  exit 1
fi

echo "[SUCCESS] Pipeline da chan loi thanh cong, ma nguon da sua dat chuan va cong chat luong coverage hoat dong tren 'main'!"
exit 0
