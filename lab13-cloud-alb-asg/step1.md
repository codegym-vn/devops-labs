# Bước 1: Khởi động nhiều backend instances

## Lý thuyết

Trong Cloud, trước khi có Load Balancer, bạn cần định nghĩa **template** cho instance (Launch Template / Instance Template) và khởi động nhiều bản từ template đó.

Trong lab: Docker image + config đóng vai template, mỗi container là một instance.

**Desired capacity**: số instance mong muốn duy trì. Auto Scaling Group sẽ:
- Tạo thêm nếu số instance < desired
- Xóa bớt nếu số instance > desired
- Giữ trong khoảng [min, max]

---

## Thực hành

### 1.1 — Tạo VPC + Subnet

```bash
# Tạo network riêng cho lab này
docker network create \
  --driver bridge \
  --subnet 10.1.0.0/24 \
  --gateway 10.1.0.1 \
  app-network

cat > /tmp/lab-env.sh << 'EOF'
export APP_NETWORK=app-network
export ASG_MIN=1
export ASG_MAX=4
export ASG_DESIRED=2
export ASG_NAME=web-asg
EOF

echo " Network app-network: 10.1.0.0/24"
```

### 1.2 — Tạo Instance Template (script khởi tạo server)

```bash
# Instance template: script sẽ chạy khi mỗi instance được tạo
# Tương đương User Data trong AWS / Startup Script trong GCP

cat > /tmp/instance-template.sh << 'TEMPLATE'
#!/bin/sh
# Script này chạy khi instance khởi động
INSTANCE_ID=$1
PORT=$2

mkdir -p /usr/share/nginx/html

cat > /usr/share/nginx/html/index.html << EOF
Instance: ${INSTANCE_ID}
Port:     ${PORT}
Status:   running
EOF

echo "healthy" > /usr/share/nginx/html/health
echo "Instance ${INSTANCE_ID} initialized"
TEMPLATE

chmod +x /tmp/instance-template.sh
echo " Instance template đã sẵn sàng"
```

### 1.3 — Khởi động instances (desired-capacity = 2)

```bash
source /tmp/lab-env.sh

# Hàm tạo một instance từ template
start_instance() {
  local ID=$1
  local PORT=$((8080 + ID))

  docker run -d \
    --name "app-${ID}" \
    --network $APP_NETWORK \
    --ip "10.1.0.1${ID}" \
    -p ${PORT}:80 \
    --label asg=$ASG_NAME \
    --label instance-id="i-00000000${ID}" \
    nginx:alpine \
    sh -c "
      mkdir -p /usr/share/nginx/html
      echo 'Instance: app-${ID}' > /usr/share/nginx/html/index.html
      echo 'healthy' > /usr/share/nginx/html/health
      echo 'app-${ID}' > /usr/share/nginx/html/server-id
      nginx -g 'daemon off;'
    "

  echo " app-${ID} → port ${PORT} (10.1.0.1${ID})"
}

# Khởi động 2 instances (desired=2)
for i in 1 2; do start_instance $i; done

echo ""
echo "=== Danh sách instances (ASG: $ASG_NAME) ==="
docker ps --filter "label=asg=$ASG_NAME" \
  --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 1.4 — Kiểm tra từng instance

```bash
for i in 1 2; do
  PORT=$((8080 + i))
  echo "app-${i} (port ${PORT}): $(curl -s http://localhost:${PORT}/server-id)"
done
```

---

## Câu hỏi

1. Tại sao dùng template thay vì tạo instance thủ công từng cái?
2. Khi ASG giảm từ 2 → 1, nó chọn instance nào để xóa?
3. **Grace period** là gì — tại sao cần chờ trước khi health check?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Tăng `desired capacity` từ 2 lên 3 — thêm instance `app-3` vào Auto Scaling Group.

Kết quả cần đạt:
- Container `app-3` đang chạy trong `app-network`, IP `10.1.0.13`, port `8083`
- Có label `asg=web-asg` (thuộc cùng ASG)
- Endpoint `/server-id` trả về text chứa `app-3`
- Endpoint `/health` trả về `healthy`

**Gợi ý khi bí:**
- Dùng hàm `start_instance` đã viết ở phần 1.3 với argument `3`
- Hoặc viết tay lệnh `docker run` theo pattern tương tự app-1 và app-2

> Nhấn **Check** khi hoàn thành.
