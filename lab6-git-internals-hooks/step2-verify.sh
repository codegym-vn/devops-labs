#!/bin/bash

REPO="/root/devops-project"

# 1. Kiem tra branch feature-payment ton tai
if ! git -C "$REPO" branch --list | grep -qw "feature-payment"; then
    echo "[ERROR] Nhanh 'feature-payment' chua duoc tao lai. Hay dung git reflog de tim SHA va tao lai nhanh nay."
    exit 1
fi

# 2. Kiem tra nhanh feature-payment co chua file payment.py
if ! git -C "$REPO" ls-tree -r feature-payment 2>/dev/null | grep -qw "payment.py"; then
    echo "[ERROR] Nhanh 'feature-payment' da duoc tao nhung khong chua file payment.py. Co the ban da tro vao nham commit."
    exit 1
fi

# 3. Kiem tra noi dung ham process_payment
if ! git -C "$REPO" show feature-payment:payment.py 2>/dev/null | grep -q "process_payment"; then
    echo "[ERROR] File payment.py tren nhanh feature-payment khong dung noi dung ban dau."
    exit 1
fi

echo "[SUCCESS] Khoi phuc du lieu thanh cong! Nhanh 'feature-payment' va file payment.py da duoc giai cuu nguyen ven nho Git Reflog."
exit 0
