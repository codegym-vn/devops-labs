#!/bin/bash
# step2-verify.sh — Lab 12: Kiểm tra Security Groups (UFW)

PASS=0; FAIL=0

check() {
  if [ "$2" = "$3" ] || ([ "$3" = "nonempty" ] && [ -n "$2" ]); then
    echo "  ✅ $1"; PASS=$((PASS+1))
  else
    echo "  ❌ $1"
    [ -n "$4" ] && echo "     Gợi ý: $4"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Bước 2: Security Groups (UFW) ==="
echo ""

# 1. UFW đang bật
UFW_STATUS=$(ufw status | grep "Status:" | awk '{print $2}')
check "UFW đang hoạt động (active)" "$UFW_STATUS" "active" \
  "Chạy: echo 'y' | ufw enable"

# 2. Port 80 được phép
PORT_80=$(ufw status | grep "^80/tcp" | grep "ALLOW" | head -1)
check "Port 80 (HTTP) đã được phép" \
  "$([ -n "$PORT_80" ] && echo ok)" "ok" \
  "Chạy: ufw allow 80/tcp"

# 3. Port 8080 được phép
PORT_8080=$(ufw status | grep "^8080/tcp\|^8080 " | grep "ALLOW" | head -1)
check "Port 8080 (HTTP alt) đã được phép" \
  "$([ -n "$PORT_8080" ] && echo ok)" "ok" \
  "Chạy: ufw allow 8080/tcp"

# 4. SSH chỉ mở cho VPC (10.0.0.0/16), không mở 0.0.0.0/0
SSH_PUBLIC=$(ufw status | grep "^22" | grep "0.0.0.0/0" | grep "ALLOW IN" | head -1)
SSH_VPC=$(ufw status | grep "22" | grep "10.0.0.0/16" | head -1)
check "Port 22 KHÔNG mở cho 0.0.0.0/0 (nguyên tắc Least Privilege)" \
  "$([ -z "$SSH_PUBLIC" ] && echo ok)" "ok" \
  "Xóa: ufw delete allow 22/tcp | Thêm: ufw allow from 10.0.0.0/16 to any port 22"

# 5. Port 8443 không được mở (đã revoke)
PORT_8443=$(ufw status | grep "8443" | grep "ALLOW" | head -1)
check "Port 8443 đã bị thu hồi (rule không cần thiết)" \
  "$([ -z "$PORT_8443" ] && echo ok)" "ok" \
  "Chạy: ufw delete allow 8443/tcp"

# 6. Default policy: deny incoming
DEFAULT_IN=$(ufw status verbose | grep "Default:" | grep "deny (incoming)")
check "Default policy: deny incoming" \
  "$([ -n "$DEFAULT_IN" ] && echo ok)" "ok" \
  "Chạy: ufw default deny incoming"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo "🎉 Security Group cấu hình đúng!" && exit 0 || exit 1

echo ""
echo "=== 🎯 Bài tập ==="
echo ""

# Challenge: port 443 chỉ từ 10.0.0.0/8, port 8443 từ 172.16.0.0/12
PORT_443_RESTRICTED=$(ufw status | grep "443" | grep "10.0.0.0/8" | head -1)
check "[Bài tập] Port 443 chỉ cho phép từ 10.0.0.0/8" \
  "$([ -n "$PORT_443_RESTRICTED" ] && echo ok)" "ok" \
  "ufw allow from 10.0.0.0/8 to any port 443 comment 'HTTPS internal'"

PORT_443_PUBLIC=$(ufw status | grep "^443" | grep "0.0.0.0/0" | grep "ALLOW IN" | head -1)
check "[Bài tập] Port 443 KHÔNG mở cho 0.0.0.0/0 (phải restricted)" \
  "$([ -z "$PORT_443_PUBLIC" ] && echo ok)" "ok" \
  "Xóa: ufw delete allow 443/tcp | Dùng: ufw allow from 10.0.0.0/8 to any port 443"

PORT_8443_CORP=$(ufw status | grep "8443" | grep "172.16.0.0/12" | head -1)
check "[Bài tập] Port 8443 chỉ cho phép từ 172.16.0.0/12" \
  "$([ -n "$PORT_8443_CORP" ] && echo ok)" "ok" \
  "ufw allow from 172.16.0.0/12 to any port 8443 comment 'API corporate'"
