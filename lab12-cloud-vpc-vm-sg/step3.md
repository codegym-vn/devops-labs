# Bước 3: Triển khai máy ảo (Compute Instance)

## Lý thuyết

**Compute Instance** (EC2 trên AWS, Compute Engine trên GCP, Virtual Machine trên Azure) là server ảo chạy trong Cloud. Mỗi instance:
- Được khởi tạo từ một **Image** (snapshot OS + phần mềm)
- Có **IP nội bộ** trong Subnet
- Được bảo vệ bởi **Security Group**
- Có thể **SSH** vào để quản lý

Vòng đời một Compute Instance:
```
Tạo (run) → pending → running → stopping → stopped → terminated
```

**SSH Key Pair** — xác thực không dùng mật khẩu:
```
Private key (.pem) → bạn giữ
Public key         → copy vào server (authorized_keys)
```

Trong lab: Docker container đóng vai Compute Instance.

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 3.1 — Tạo SSH Key Pair

```bash
# Tạo key Ed25519 (thuật toán an toàn hơn RSA)
ssh-keygen -t ed25519 -f /tmp/lab-keypair -N "" -C "lab-instance-key"

echo " Key Pair đã tạo:"
ls -la /tmp/lab-keypair*
cat /tmp/lab-keypair.pub
```

### 3.2 — Triển khai web server (Compute Instance)

```bash
# Tạo cấu hình Nginx cho web server
cat > /tmp/web-server.conf << 'EOF'
server {
    listen 80;
    location / {
        return 200 "Server: web-server-1\nSubnet: public (10.0.1.0/24)\nIP: 10.0.1.10\n";
        add_header Content-Type text/plain;
    }
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    location /info {
        return 200 "Instance info:\n  Role: web\n  Environment: production\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Khởi động instance (container đóng vai EC2/VM)
docker run -d \
  --name web-server-1 \
  --network public-subnet \
  --ip 10.0.1.10 \
  -p 8081:80 \
  -v /tmp/web-server.conf:/etc/nginx/conf.d/default.conf:ro \
  --label Name=web-server-1 \
  --label Role=web \
  --label Environment=production \
  --label Subnet=public \
  nginx:alpine

echo " web-server-1 đang chạy:"
docker ps --filter "name=web-server-1" --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}\t{{.Ports}}"
```

### 3.3 — Triển khai database server (Private Subnet)

```bash
# Database chỉ ở Private Subnet — không có port ra ngoài
docker run -d \
  --name db-server-1 \
  --network private-subnet \
  --ip 10.0.2.10 \
  --label Name=db-server-1 \
  --label Role=database \
  --label Environment=production \
  --label Subnet=private \
  alpine sh -c "
    while true; do
      echo 'DB Server running on 10.0.2.10'
      sleep 30
    done
  "

echo " db-server-1 đang chạy trong Private Subnet (không có port public)"
```

### 3.4 — SSH vào Instance

```bash
# AWS thật: ssh -i keypair.pem ubuntu@<PUBLIC_IP>
# GCP:     gcloud compute ssh <INSTANCE_NAME>
# Lab:     docker exec (tương đương SSH vào container)

echo "=== SSH vào web-server-1 ==="
docker exec -it web-server-1 sh -c "
  echo 'Đang ở trong instance web-server-1'
  echo 'IP: \$(hostname -i)'
  echo 'OS: \$(cat /etc/alpine-release)'
  echo 'Running processes:'
  ps aux | grep nginx | head -3
"
```

### 3.5 — Kiểm thử HTTP từ ngoài vào

```bash
echo "=== Test từ Internet vào Web Server ==="
curl http://localhost:8081
echo ""

curl http://localhost:8081/health
echo ""

curl -w "Response time: %{time_total}s\n" -o /dev/null -s http://localhost:8081

echo ""
echo "=== DB Server KHÔNG accessible từ ngoài ==="
nc -z -w2 localhost 5432 2>/dev/null && echo "OPEN " || echo "BLOCKED  (đúng thiết kế)"
```

### 3.6 — Kiểm tra kết nối giữa các Subnet

```bash
# Trong Cloud: các server cùng VPC nói chuyện được qua IP nội bộ
# Cần kết nối 2 network bằng thêm network alias

docker network connect public-subnet db-server-1 2>/dev/null || true

echo "=== Web Server gọi DB Server (internal VPC traffic) ==="
docker exec web-server-1 sh -c "
  wget -q -O/dev/null http://10.0.2.10 2>&1 || echo '(DB không có HTTP — OK, chỉ test connectivity)'
  ping -c 2 10.0.2.10 2>/dev/null || echo 'ping: 10.0.2.10 reachable qua VPC'
"

cat >> /tmp/lab-env.sh << 'EOF'
export WEB_CONTAINER=web-server-1
export DB_CONTAINER=db-server-1
EOF
```

---

## Tương đương trên Cloud

| Lab (Docker) | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| `docker run --network public-subnet` | `aws ec2 run-instances --subnet-id <public>` | `gcloud compute instances create --network <vpc>` | `az vm create --vnet-name` |
| `--label Name=web-server-1` | Tag: `Key=Name,Value=web-server-1` | Label: `name=web-server-1` | Tag: `Name=web-server-1` |
| `docker exec` | SSH với keypair | `gcloud compute ssh` | `az ssh vm` |
| Port mapping `-p 8081:80` | Elastic IP + Security Group | External IP + Firewall rule | Public IP + NSG |

---

## Câu hỏi

1. Tại sao phải `chmod 400` file private key `.pem`?
2. Sự khác biệt giữa `stop` và `terminate` một Compute Instance?
3. Tại sao Public IP của instance thay đổi sau mỗi lần restart (nếu không dùng Elastic/Static IP)?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Deploy một API server tách biệt với web server hiện tại.

Tạo container `api-server` với các yêu cầu sau:
- Network: `public-subnet`, IP: `10.0.1.11`
- Expose ra ngoài tại port `8082`
- Endpoint `/api/status` phải trả về JSON text với hai field: `status` (giá trị "ok") và `service` (giá trị "api")
- Có labels: `Role=api`, `Environment=production`

**Gợi ý khi bí:**
- Xem cách tạo `web-server.conf` ở phần 3.2 — tạo Nginx config tương tự
- Dùng `return 200` trả về JSON string trong Nginx — xem cú pháp tại phần 3.2
- `add_header Content-Type application/json;`

> Nhấn **Check** khi hoàn thành.
