#!/bin/bash
# step1-verify.sh — Lab 15: Kiem tra Named Volume va Data Persistence

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ] || ([ "$3" = "nonempty" ] && [ -n "$2" ]); then
    echo "   $1"; PASS=$((PASS+1))
  else
    echo "   $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 1: Kiểm Tra Named Volume & Khả Năng Lưu Trữ Bền Vững ==="
echo ""

# 1. Kiem tra volume app_data ton tai
VOL_EXISTS=$(docker volume inspect app_data >/dev/null 2>&1 && echo "ok" || echo "")
check "Named Volume 'app_data' đã được khởi tạo" \
  "$VOL_EXISTS" "ok" \
  "Chạy lệnh: docker volume create app_data"

# 2. Kiem tra container reader-box dang running
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' reader-box 2>/dev/null)
check "Container 'reader-box' đang ở trạng thái RUNNING" \
  "$IS_RUNNING" "true" \
  "Chạy lệnh: docker run -d --name reader-box -v app_data:/data alpine:3.19 sleep 3600"

# 3. Kiem tra volume app_data duoc mount dung vao /data cua reader-box
MOUNT_DEST=$(docker inspect -f '{{range .Mounts}}{{if eq .Name "app_data"}}{{.Destination}}{{end}}{{end}}' reader-box 2>/dev/null)
check "Volume 'app_data' được gắn chính xác vào thư mục '/data' của reader-box" \
  "$MOUNT_DEST" "/data" \
  "Đảm bảo tham số: -v app_data:/data khi chạy container reader-box"

# 4. Kiem tra noi dung file /data/message.txt
FILE_CONTENT=$(docker exec reader-box cat /data/message.txt 2>/dev/null | tr -d '\r\n')
check "Dữ liệu /data/message.txt được bảo toàn qua vòng đời container" \
  "$(echo "$FILE_CONTENT" | grep -q "DevOps Data Persistence" && echo "ok" || echo "")" "ok" \
  "Kiểm tra lại nội dung ghi vào file /data/message.txt trong volume app_data"

echo ""
if [ $FAIL -eq 0 ]; then
  echo " [SUCCESS] Xuất sắc! Bạn đã làm chủ cơ chế lưu trữ bền vững với Docker Named Volume!"
  exit 0
else
  echo " Có $FAIL tiêu chí chưa đạt. Hãy xem các gợi ý ở trên để hoàn thiện."
  exit 1
fi
