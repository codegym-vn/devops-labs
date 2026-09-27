#!/bin/bash
# step1-verify.sh — Lab 12: Kiểm tra VPC + Subnet

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

echo "=== Bước 1: VPC + Subnet ==="
echo ""

# 1. Network public-subnet tồn tại với subnet đúng
PUBLIC_SUBNET=$(docker network inspect public-subnet \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
check "Network 'public-subnet' tồn tại với CIDR 10.0.1.0/24" \
  "$PUBLIC_SUBNET" "10.0.1.0/24" \
  "Chạy: docker network create --subnet 10.0.1.0/24 --gateway 10.0.1.1 public-subnet"

# 2. Network private-subnet tồn tại
PRIVATE_SUBNET=$(docker network inspect private-subnet \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
check "Network 'private-subnet' tồn tại với CIDR 10.0.2.0/24" \
  "$PRIVATE_SUBNET" "10.0.2.0/24" \
  "Chạy: docker network create --subnet 10.0.2.0/24 --gateway 10.0.2.1 private-subnet"

# 3. web-server container đang chạy trong public-subnet
WEB_NET=$(docker inspect web-server \
  --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' 2>/dev/null)
check "Container 'web-server' chạy trong public-subnet" \
  "$WEB_NET" "public-subnet" \
  "Chạy: docker run -d --name web-server --network public-subnet --ip 10.0.1.10 ..."

# 4. web-server có IP 10.0.1.10
WEB_IP=$(docker inspect web-server \
  --format '{{.NetworkSettings.Networks.public-subnet.IPAddress}}' 2>/dev/null)
check "web-server có IP 10.0.1.10" "$WEB_IP" "10.0.1.10" \
  "Thêm --ip 10.0.1.10 vào lệnh docker run"

# 5. db-server chạy trong private-subnet (KHÔNG expose port ra ngoài)
DB_PORTS=$(docker inspect db-server \
  --format '{{.HostConfig.PortBindings}}' 2>/dev/null)
check "db-server không có port public (Private Subnet)" \
  "$DB_PORTS" "map[]" \
  "Tạo db-server với --network private-subnet và KHÔNG dùng -p"

# 6. /tmp/lab-env.sh tồn tại
check "File /tmp/lab-env.sh đã lưu biến môi trường" \
  "$(test -f /tmp/lab-env.sh && echo ok)" "ok" \
  "Chạy phần 1.5 trong hướng dẫn để lưu biến"

echo ""
echo "===  Bài tập ==="
echo ""

# Challenge: tạo db-subnet (10.0.3.0/24) và container db-replica
DB_SUBNET=$(docker network inspect db-subnet \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null)
check "[Bài tập] Network 'db-subnet' tồn tại với CIDR 10.0.3.0/24" \
  "$(echo $DB_SUBNET | grep -c '10.0.3')" "1" \
  "docker network create --subnet 10.0.3.0/24 --gateway 10.0.3.1 \\
         --label subnet=database --label vpc=devops-vpc db-subnet"

DB_SUBNET_LABEL=$(docker network inspect db-subnet \
  --format '{{index .Labels "subnet"}}' 2>/dev/null)
check "[Bài tập] Network 'db-subnet' có label subnet=database" \
  "$DB_SUBNET_LABEL" "database" \
  "Thêm --label subnet=database vào lệnh docker network create"

DB_REPLICA_IP=$(docker inspect db-replica \
  --format '{{.NetworkSettings.Networks.db-subnet.IPAddress}}' 2>/dev/null)
check "[Bài tập] Container 'db-replica' chạy trong db-subnet với IP 10.0.3.10" \
  "$DB_REPLICA_IP" "10.0.3.10" \
  "docker run -d --name db-replica --network db-subnet --ip 10.0.3.10 alpine sleep infinity"

DB_REPLICA_PORTS=$(docker inspect db-replica \
  --format '{{.HostConfig.PortBindings}}' 2>/dev/null)
check "[Bài tập] db-replica không expose port ra ngoài" \
  "$DB_REPLICA_PORTS" "map[]" \
  "Xóa flag -p khi tạo db-replica"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Kết quả: $PASS/$((PASS+FAIL)) kiểm tra thành công"
[ $FAIL -eq 0 ] && echo " Hoàn thành Bước 1!" && exit 0 || exit 1
