#!/bin/bash
# ============================================================
# background.sh — Khởi tạo môi trường Lab 12: Cloud VPC + VM + Security Groups
# Chạy ngầm, học viên không thấy output
# ============================================================

set -e

LOG="/var/log/lab-init.log"
exec > "$LOG" 2>&1

echo "[$(date)] Bắt đầu khởi tạo môi trường..."

# --- 1. Cài đặt dependencies ---
apt-get update -q
apt-get install -y -q \
  python3 python3-pip python3-venv \
  curl unzip jq netcat-openbsd \
  docker.io

systemctl enable docker
systemctl start docker

# --- 2. Cài AWS CLI v2 ---
echo "[$(date)] Cài đặt AWS CLI..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# --- 3. Cài LocalStack ---
echo "[$(date)] Cài đặt LocalStack..."
pip3 install -q localstack localstack-client awscli-local

# --- 4. Cấu hình AWS CLI credentials giả (LocalStack không cần thật) ---
mkdir -p /root/.aws
cat > /root/.aws/credentials << 'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

cat > /root/.aws/config << 'EOF'
[default]
region = ap-southeast-1
output = json
EOF

# --- 5. Alias aws -> awslocal (tự động thêm --endpoint-url) ---
echo 'alias aws="aws --endpoint-url=http://localhost:4566"' >> /root/.bashrc
echo 'export AWS_DEFAULT_REGION=ap-southeast-1' >> /root/.bashrc
echo 'export AWS_ACCESS_KEY_ID=test' >> /root/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY=test' >> /root/.bashrc

# --- 6. Khởi động LocalStack ---
echo "[$(date)] Khởi động LocalStack..."
LOCALSTACK_VOLUME_DIR=/var/lib/localstack localstack start -d

# --- 7. Chờ LocalStack sẵn sàng ---
echo "[$(date)] Chờ LocalStack khởi động..."
for i in $(seq 1 60); do
  if curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2": "available"'; then
    echo "[$(date)] LocalStack sẵn sàng sau ${i}s"
    break
  fi
  sleep 2
done

# --- 8. Chuẩn bị Docker image để dùng làm "EC2 instance" ---
echo "[$(date)] Kéo Docker image nginx:alpine..."
docker pull nginx:alpine -q

# --- 9. Tạo script helper cho học viên ---
cat > /usr/local/bin/lab-status << 'EOF'
#!/bin/bash
echo "=== Trạng thái môi trường Lab ==="
echo ""
# LocalStack
if curl -sf http://localhost:4566/_localstack/health >/dev/null 2>&1; then
  echo "✅ LocalStack  : đang chạy (http://localhost:4566)"
else
  echo "❌ LocalStack  : chưa sẵn sàng"
fi
# Docker
if docker ps >/dev/null 2>&1; then
  echo "✅ Docker      : đang chạy"
else
  echo "❌ Docker      : lỗi"
fi
# AWS CLI
if aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs >/dev/null 2>&1; then
  echo "✅ AWS CLI     : kết nối LocalStack OK"
else
  echo "❌ AWS CLI     : chưa kết nối được"
fi
echo ""
echo "Biến môi trường:"
echo "  AWS_DEFAULT_REGION = $AWS_DEFAULT_REGION"
echo "  Endpoint           = http://localhost:4566"
EOF
chmod +x /usr/local/bin/lab-status

echo "[$(date)] ✅ Khởi tạo môi trường hoàn tất"
touch /tmp/lab-ready
