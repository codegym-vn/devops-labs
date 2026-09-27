# Bước 3: Kiểm thử phân tải và quan sát round-robin

## Lý thuyết

**Thuật toán Least Connections** (đang dùng trong Nginx upstream):
- Mỗi request mới được gửi đến backend có **ít kết nối đang xử lý nhất**
- Tốt hơn Round Robin khi các request có thời gian xử lý khác nhau
- Phù hợp với long-polling, file upload, streaming

**Sticky Session (IP Hash)**:
- Mọi request từ cùng một IP → luôn đến cùng một backend
- Hữu ích cho ứng dụng lưu session phía server (không khuyến khích, nên dùng Redis)

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 3.1 — Quan sát round-robin qua /server-id

```bash
echo "=== Kiểm thử phân tải: 10 request liên tiếp ==="
for i in $(seq 1 10); do
  RESPONSE=$(curl -s http://localhost/server-id)
  echo "Request $i: $RESPONSE"
done
```

Kết quả mong đợi — traffic xen kẽ giữa 2 backend:
```
Request 1: Server: app-1 | Instance: i-000000000001 | AZ: ap-southeast-1a
Request 2: Server: app-2 | Instance: i-000000000002 | AZ: ap-southeast-1a
Request 3: Server: app-1 | ...
Request 4: Server: app-2 | ...
```

---

### 3.2 — Đếm tỷ lệ phân phối

```bash
echo "=== Phân tích phân phối 100 request ==="
declare -A COUNT
for i in $(seq 1 100); do
  SERVER=$(curl -s http://localhost/server-id | grep -oP 'app-\d+')
  COUNT[$SERVER]=$((${COUNT[$SERVER]:-0} + 1))
done

echo ""
echo "Kết quả phân phối:"
for SERVER in "${!COUNT[@]}"; do
  TOTAL=100
  PCT=$(( COUNT[$SERVER] * 100 / TOTAL ))
  BAR=$(printf '█%.0s' $(seq 1 $((PCT / 2))))
  printf "  %-8s: %3d requests (%d%%) %s\n" "$SERVER" "${COUNT[$SERVER]}" "$PCT" "$BAR"
done
echo ""
echo "Lý tưởng: mỗi server ~50% (±5% chấp nhận được)"
```

---

### 3.3 — Benchmark throughput với wrk

```bash
echo "=== Benchmark trước khi scale (2 backends) ==="
wrk -t4 -c50 -d15s http://localhost/server-id
```

Ghi lại kết quả:
```
Running 15s test @ http://localhost/server-id
  4 threads and 50 connections
  Thread Stats   Avg       Stdev     Max
    Latency     X.XXms    X.XXms    XXXms
    Req/Sec    XXXX      XXXX      XXXXX
  Requests/sec: XXXXX  ← ghi lại số này
```

---

### 3.4 — Kiểm thử Health Check: mô phỏng instance bị lỗi

```bash
echo "=== Mô phỏng instance app-2 bị lỗi ==="

# Xóa health endpoint của app-2
docker exec app-2 sh -c "rm /usr/share/nginx/html/health && echo 'error' > /usr/share/nginx/html/health"

# Thử nghiệm: ALB không nên route vào app-2 nữa
echo "Sau khi app-2 bị lỗi — 10 request tiếp theo:"
for i in $(seq 1 10); do
  curl -s http://localhost/server-id
  echo ""
done

# Phục hồi app-2
docker exec app-2 sh -c "echo 'healthy' > /usr/share/nginx/html/health"
echo "✅ app-2 đã phục hồi"
```

> 💡 Trong Nginx Least Conn, backend lỗi sẽ bị đánh dấu `down` sau khi `max_fails` lần health check thất bại. Để cấu hình: thêm `max_fails=3 fail_timeout=10s` vào upstream.

---

### 3.5 — Thêm Health Check chủ động vào Nginx upstream

```bash
cat > /etc/nginx/conf.d/alb.conf << 'EOF'
upstream backend {
    least_conn;
    server localhost:8081 max_fails=3 fail_timeout=10s;
    server localhost:8082 max_fails=3 fail_timeout=10s;
    keepalive 32;
}

server {
    listen 80 default_server;

    location / {
        proxy_pass         http://backend;
        proxy_http_version 1.1;
        proxy_set_header   Connection "";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        add_header         X-Served-By $upstream_addr always;
    }

    location /health {
        proxy_pass http://backend/health;
    }

    location /server-id {
        proxy_pass http://backend/server-id;
    }
}
EOF

nginx -t && nginx -s reload
echo "✅ Nginx đã cập nhật với passive health check"
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tỷ lệ phân phối có bao giờ đạt **chính xác 50/50** không? Tại sao?
2. **Passive health check** (Nginx `max_fails`) và **Active health check** (AWS ALB `HealthCheck`) khác nhau như thế nào?
3. Nếu app-1 xử lý request nhanh hơn app-2 gấp đôi, thuật toán nào phù hợp hơn: Round Robin hay Least Connections?
