#!/bin/bash
# step3-verify.sh — Kiểm tra Bước 3: EC2 Instance + Docker container

source /tmp/lab-env.sh 2>/dev/null || true

PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  local expected="$3"
  if [ "$result" = "$expected" ]; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc (nhận: '$result', cần: '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

check_contains() {
  local desc="$1"
  local result="$2"
  local pattern="$3"
  if echo "$result" | grep -q "$pattern"; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc (không tìm thấy '$pattern' trong kết quả)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Kiểm tra Bước 3: EC2 Instance và Docker Container ==="
echo ""

# 1. Key Pair đã được tạo
KEYPAIR=$(aws ec2 describe-key-pairs \
  --key-names devops-keypair \
  --query 'KeyPairs[0].KeyName' --output text 2>/dev/null)
check "Key Pair 'devops-keypair' đã được tạo" "$KEYPAIR" "devops-keypair"

# 2. Private key file tồn tại với quyền 400
if [ -f ~/.ssh/devops-keypair.pem ]; then
  PERM=$(stat -c "%a" ~/.ssh/devops-keypair.pem 2>/dev/null || stat -f "%OLp" ~/.ssh/devops-keypair.pem 2>/dev/null)
  check "Private key có quyền 400 (chỉ owner đọc)" "$PERM" "400"
else
  echo "  ❌ File ~/.ssh/devops-keypair.pem chưa tồn tại"
  FAIL=$((FAIL + 1))
fi

# 3. EC2 instance đã được đăng ký
INST_STATE=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server-1" \
  --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
check "EC2 instance 'web-server-1' đã đăng ký với AWS API" "$INST_STATE" "running"

# 4. Docker container đang chạy
CONTAINER_STATUS=$(docker inspect web-server-1 \
  --format '{{.State.Status}}' 2>/dev/null)
check "Docker container 'web-server-1' đang chạy" "$CONTAINER_STATUS" "running"

# 5. HTTP server phản hồi 200
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
check "Web server phản hồi HTTP 200" "$HTTP_CODE" "200"

# 6. Health endpoint hoạt động
HEALTH=$(curl -s http://localhost:8080/health 2>/dev/null)
check_contains "Health endpoint trả về 'healthy'" "$HEALTH" "healthy"

# 7. Container có label ec2-instance-id
LABEL=$(docker inspect web-server-1 \
  --format '{{index .Config.Labels "ec2-instance-id"}}' 2>/dev/null)
check_contains "Container được gắn EC2 Instance ID" "$LABEL" "i-"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS thành công / $((PASS + FAIL)) kiểm tra"

if [ $FAIL -eq 0 ]; then
  echo "🎉 Instance đã triển khai thành công! Tiếp tục Bước 4."
  exit 0
else
  echo "⚠️  Có $FAIL lỗi. Đọc lại hướng dẫn và thử lại."
  exit 1
fi
