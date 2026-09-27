# Bước 2: Cấu hình Load Balancer và Health Check

## Lý thuyết

**Load Balancer** nhận traffic từ client và phân phối đến các backend instances. Các thuật toán phổ biến:

| Thuật toán | Cách hoạt động | Phù hợp khi |
|-----------|---------------|-------------|
| Round Robin | Lần lượt từng server | Request có thời gian xử lý tương đương |
| Least Connections | Server ít kết nối nhất | Request có thời gian xử lý khác nhau |
| IP Hash | Cùng IP → cùng server | Cần session persistence |

**Health Check**: Load Balancer định kỳ gọi `GET /health` → phải nhận HTTP 200:
- Pass: instance ở trong rotation
- Fail (N lần liên tiếp): tạm loại khỏi rotation
- Phục hồi: tự động thêm lại

**Connection Draining**: khi instance bị xóa, Load Balancer chờ request hiện tại hoàn thành trước khi ngắt.

Trong lab: Nginx đóng vai Load Balancer (đã học Lab 4).

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Cấu hình Nginx Load Balancer

```bash
cat > /etc/nginx/conf.d/lb.conf << 'EOF'
upstream backend {
    least_conn;
    server localhost:8081 max_fails=3 fail_timeout=10s;
    server localhost:8082 max_fails=3 fail_timeout=10s;
    keepalive 32;
}

server {
    listen 80 default_server;

    # Phân tải traffic đến backend
    location / {
        proxy_pass         http://backend;
        proxy_http_version 1.1;
        proxy_set_header   Connection "";
        proxy_set_header   Host $host;
        add_header         X-Served-By $upstream_addr always;
    }

    # Health check endpoint của LB
    location /lb-health {
        return 200 "Load Balancer OK\n";
        add_header Content-Type text/plain;
    }

    location /health    { proxy_pass http://backend/health; }
    location /server-id { proxy_pass http://backend/server-id; }
}
EOF

rm -f /etc/nginx/sites-enabled/default
nginx -t && nginx -s reload
echo " Load Balancer sẵn sàng tại port 80"
```

### 2.2 — Kiểm tra LB hoạt động

```bash
# LB health
curl http://localhost/lb-health

# Request đến backend qua LB
echo "=== 5 request — xem được phân phối thế nào ==="
for i in $(seq 1 5); do
  RESPONSE=$(curl -s http://localhost/server-id)
  BACKEND=$(curl -s -I http://localhost/server-id | grep -i "x-served-by" | awk '{print $2}')
  echo "  Request $i → $RESPONSE (backend: $BACKEND)"
done
```

### 2.3 — Tạo script Health Check monitoring

```bash
cat > /tmp/health-monitor.sh << 'EOF'
#!/bin/bash
# Script monitoring health của tất cả instances
# Tương đương CloudWatch Health Check trong AWS

BACKENDS=("localhost:8081" "localhost:8082")
echo "=== Health Check Report $(date) ==="

for BACKEND in "${BACKENDS[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${BACKEND}/health)
  LATENCY=$(curl -s -o /dev/null -w "%{time_total}" http://${BACKEND}/health)
  if [ "$STATUS" = "200" ]; then
    echo "   $BACKEND — HTTP $STATUS (${LATENCY}s)"
  else
    echo "   $BACKEND — HTTP $STATUS UNHEALTHY"
  fi
done
EOF

chmod +x /tmp/health-monitor.sh
/tmp/health-monitor.sh
```

### 2.4 — Giả lập instance unhealthy

```bash
echo "=== Mô phỏng app-2 bị lỗi ==="
docker exec app-2 sh -c "echo 'error' > /usr/share/nginx/html/health"

echo "Health check sau khi app-2 lỗi:"
/tmp/health-monitor.sh

echo ""
echo "10 request — LB nên ngừng gửi vào app-2 (sau max_fails=3):"
for i in $(seq 1 10); do
  curl -s http://localhost/server-id
  echo ""
done

# Phục hồi app-2
docker exec app-2 sh -c "echo 'healthy' > /usr/share/nginx/html/health"
echo " app-2 đã phục hồi"
```

---

## Tương đương trên Cloud

| Lab (Nginx) | AWS ALB | GCP Load Balancing | Azure LB |
|-------------|---------|-------------------|----------|
| `least_conn` | Round Robin (mặc định) | Round Robin | Hash |
| `max_fails=3 fail_timeout=10s` | Healthy threshold: 2, Unhealthy: 3 | Health check | Probe |
| `keepalive 32` | Connection reuse | - | - |
| `/health` endpoint | Health check path | Health check path | Health probe path |

---

## Câu hỏi

1. Tại sao Health Check dùng `/health` thay vì `/`?
2. Connection Draining giải quyết vấn đề gì khi xóa instance đang có traffic?
3. LB có thể định tuyến theo path (`/api/*` vs `/static/*`) không? Loại LB nào hỗ trợ điều này?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Thêm endpoint `/metrics` vào Nginx Load Balancer. Endpoint này trả về thống kê đơn giản:

```
upstream: backend
algorithm: least_conn
servers: 2
status: active
```

Endpoint phải trả về `Content-Type: text/plain` và HTTP 200.

**Gợi ý khi bí:**
- Thêm một location block tên  vào block  trong file 
- Dùng  trả về text — xem cách viết ở phần 2.1
- Đừng quên chạy  sau khi sửa config

> Nhấn **Check** khi hoàn thành.
