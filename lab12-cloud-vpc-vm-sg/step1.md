# Bước 1: Tạo VPC và Subnet

## Lý thuyết

**VPC** là mạng ảo riêng — tất cả servers bên trong cùng VPC có thể nói chuyện với nhau qua IP nội bộ, nhưng tách biệt hoàn toàn với VPC khác.

**Subnet** chia VPC thành các vùng nhỏ hơn:
- **Public Subnet**: có đường ra Internet (các web server, load balancer)
- **Private Subnet**: không có đường ra Internet trực tiếp (database, internal services)

```
VPC: 10.0.0.0/16
  ├── Public Subnet:  10.0.1.0/24  → Web servers
  └── Private Subnet: 10.0.2.0/24  → Databases
```

Trong Docker, VPC = **Docker network** với custom subnet.

---

## Thực hành

### 1.1 — Tạo VPC (Docker network)

```bash
# Tạo VPC: mạng ảo riêng với CIDR 10.0.0.0/16
docker network create \
  --driver bridge \
  --subnet 10.0.0.0/16 \
  --gateway 10.0.0.1 \
  --label vpc=devops-vpc \
  devops-vpc

echo " VPC 'devops-vpc' đã tạo"
docker network ls | grep devops-vpc
```

### 1.2 — Tạo Public Subnet

```bash
# Subnet public: 10.0.1.0/24 — cho web servers
docker network create \
  --driver bridge \
  --subnet 10.0.1.0/24 \
  --gateway 10.0.1.1 \
  --label subnet=public \
  --label vpc=devops-vpc \
  public-subnet

echo " Public Subnet 10.0.1.0/24"
```

### 1.3 — Tạo Private Subnet

```bash
# Subnet private: 10.0.2.0/24 — cho database, internal services
docker network create \
  --driver bridge \
  --subnet 10.0.2.0/24 \
  --gateway 10.0.2.1 \
  --label subnet=private \
  --label vpc=devops-vpc \
  private-subnet

echo " Private Subnet 10.0.2.0/24"
docker network ls | grep subnet
```

### 1.4 — Triển khai server vào từng Subnet

```bash
# Web server → Public Subnet (có port ra ngoài = có Internet Gateway)
docker run -d \
  --name web-server \
  --network public-subnet \
  --ip 10.0.1.10 \
  -p 8080:80 \
  --label role=web \
  --label environment=production \
  nginx:alpine

# Database → Private Subnet (KHÔNG có port ra ngoài)
docker run -d \
  --name db-server \
  --network private-subnet \
  --ip 10.0.2.10 \
  --label role=database \
  --label environment=production \
  alpine sleep infinity

echo " Web server: 10.0.1.10 (port 8080 ra ngoài)"
echo " DB server:  10.0.2.10 (chỉ nội bộ)"
docker ps --format "table {{.Names}}\t{{.Networks}}\t{{.Ports}}"
```

### 1.5 — Kiểm tra isolation

```bash
# Web server CÓ THỂ truy cập ra ngoài (public)
echo "=== Web server ping ra ngoài ==="
docker exec web-server wget -q -O- http://httpbin.org/ip 2>/dev/null | head -3 || echo "(không có internet trong lab — OK)"

# DB server KHÔNG có port ra ngoài — chỉ internal
echo "=== DB server: không có port public ==="
docker inspect db-server --format '{{.NetworkSettings.Ports}}' 
# Kết quả: map[] = không có port nào expose ra ngoài

# Lưu biến môi trường
cat > /tmp/lab-env.sh << 'EOF'
export VPC_NETWORK=devops-vpc
export PUBLIC_SUBNET=public-subnet
export PRIVATE_SUBNET=private-subnet
export WEB_SERVER_IP=10.0.1.10
export DB_SERVER_IP=10.0.2.10
EOF
echo " Lưu vào /tmp/lab-env.sh"
```

---

## Câu hỏi

1. Tại sao database nên nằm ở **Private Subnet** thay vì Public Subnet?
2. Trong bài lab, điều gì đóng vai trò **Internet Gateway** (cổng ra Internet)?
3. Nếu VPC có CIDR `10.0.0.0/16`, có thể tạo tối đa bao nhiêu Subnet `/24`?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Hệ thống cần thêm một Subnet chuyên dụng cho database layer.

Tạo một Docker network mới với các thuộc tính sau:
- Tên: `db-subnet`
- CIDR: `10.0.3.0/24`, gateway: `10.0.3.1`
- Label: `subnet=database` và `vpc=devops-vpc`

Sau khi tạo xong, khởi động container `db-replica` vào network này với IP `10.0.3.10`, không expose port ra ngoài.

**Gợi ý khi bí:**
- Xem lại lệnh ở phần 1.3 và 1.4 — cú pháp tương tự
- `docker network inspect db-subnet` để kiểm tra kết quả

> Nhấn **Check** khi hoàn thành.
