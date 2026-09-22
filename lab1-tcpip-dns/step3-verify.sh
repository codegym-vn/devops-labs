#!/bin/bash

# Kiểm tra phân giải tên miền myapp.internal qua getent hoặc trực tiếp trong /etc/hosts
if getent hosts myapp.internal 2>/dev/null | grep -q "127\.0\.0\.1" || grep -E -q '^\s*127\.0\.0\.1\s+.*myapp\.internal' /etc/hosts 2>/dev/null; then
    echo "[SUCCESS] Tên miền myapp.internal đã được map thành công về 127.0.0.1 trong /etc/hosts."
    exit 0
else
    echo "[ERROR] Chưa tìm thấy bản ghi phân giải '127.0.0.1 myapp.internal'. Hãy kiểm tra lại nội dung file /etc/hosts."
    exit 1
fi
