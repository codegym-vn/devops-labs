#!/bin/bash

OUT_FILE="/tmp/diag-output.txt"
ERR_FILE="/tmp/diag-error.txt"
COMB_FILE="/tmp/diag-combined.txt"

if [ ! -f "$OUT_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $OUT_FILE. Hãy chuyển hướng stdout vào file này."
    exit 1
fi

if ! grep -q "\[OK\]" "$OUT_FILE" || grep -q "\[ERROR\]" "$OUT_FILE"; then
    echo "[ERROR] File $OUT_FILE chưa chuẩn. File chỉ được chứa các dòng thành công [OK] (stdout) và không được lẫn thông báo [ERROR] (stderr)."
    exit 1
fi

if [ ! -f "$ERR_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $ERR_FILE. Hãy chuyển hướng riêng stderr vào file này."
    exit 1
fi

if ! grep -q "\[ERROR\]" "$ERR_FILE" || grep -q "\[OK\]" "$ERR_FILE"; then
    echo "[ERROR] File $ERR_FILE chưa chuẩn. File chỉ được chứa các dòng thông báo lỗi [ERROR] (stderr) và không được lẫn dòng [OK]."
    exit 1
fi

if [ ! -f "$COMB_FILE" ]; then
    echo "[ERROR] Chưa tìm thấy file $COMB_FILE."
    exit 1
fi

if ! grep -q "\[OK\]" "$COMB_FILE" || ! grep -q "\[ERROR\]" "$COMB_FILE"; then
    echo "[ERROR] File $COMB_FILE phải chứa hợp nhất CẢ dòng [OK] và dòng [ERROR] bằng toán tử '2>&1' hoặc '&>'."
    exit 1
fi

echo "[SUCCESS] Hoàn hảo! Bạn đã làm chủ hoàn toàn kỹ thuật phân tách và hợp nhất các luồng stdin/stdout/stderr trong Linux."
exit 0
