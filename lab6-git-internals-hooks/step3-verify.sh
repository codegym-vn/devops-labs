#!/bin/bash

REPO="/root/devops-project"
HOOK="$REPO/.git/hooks/pre-commit"

# 1. Kiem tra hook ton tai
if [ ! -f "$HOOK" ]; then
    echo "[ERROR] File hook $HOOK chua duoc tao."
    exit 1
fi

# 2. Kiem tra quyen thuc thi
if [ ! -x "$HOOK" ]; then
    echo "[ERROR] File hook $HOOK chua co quyen thuc thi. Hay chay lenh: chmod +x $HOOK"
    exit 1
fi

# 3. Kiem tra tinh nang chan commit chua AWS_SECRET_KEY=
TEST_FILE="$REPO/.verify_secret_test.txt"
echo "AWS_SECRET_KEY=test_verification_token_999" > "$TEST_FILE"
git -C "$REPO" add .verify_secret_test.txt > /dev/null 2>&1

BLOCKED=false
if ! git -C "$REPO" commit -m "chore: verify test commit with secret" > /dev/null 2>&1; then
    BLOCKED=true
fi

# Don dep file test vi pham
git -C "$REPO" reset HEAD .verify_secret_test.txt > /dev/null 2>&1
rm -f "$TEST_FILE"

if [ "$BLOCKED" = true ]; then
    echo "[SUCCESS] Pre-commit hook hoat dong hoan hao! Commit chua 'AWS_SECRET_KEY=' da bi tu choi thanh cong."
    exit 0
else
    # Neu commit khong bi chan, huy commit test vua tao
    git -C "$REPO" reset --hard HEAD~1 > /dev/null 2>&1
    echo "[ERROR] Hook pre-commit khong chan duoc commit chua AWS_SECRET_KEY=. Hay kiem tra lai script trong $HOOK."
    exit 1
fi
