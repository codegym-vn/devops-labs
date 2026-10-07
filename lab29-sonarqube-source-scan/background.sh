#!/bin/bash
set -e

# 1. Tao 2GB Swap de bao ve RAM may ao khong bi OOM Freeze khi chay nhieu tien trinh Java
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null || true
  chmod 600 /swapfile 2>/dev/null || true
  mkswap /swapfile >/dev/null 2>&1 || true
  swapon /swapfile >/dev/null 2>&1 || true
fi

# 2. Cau hinh bo nho Elasticsearch cho SonarQube
sysctl -w vm.max_map_count=262144 > /dev/null 2>&1 || true

# 3. Khoi tao ngay thu muc du an mau
mkdir -p /root/sonarqube-lab/src
cd /root/sonarqube-lab

cat << 'EOF' > src/app.py
# Code Smell 1: Bien khong su dung (Unused variable)
unused_variable = "This is not used anywhere"

# Code Smell 2: Password hardcode dang comment
# admin_pass = "123456"

def welcome():
    print("Welcome to SonarQube SAST Demo Service")

if __name__ == "__main__":
    welcome()
EOF

touch /tmp/background-finished
