# Bước 4: Auto Scaling — Scale-out và dọn dẹp

## Lý thuyết

**Auto Scaling** tự động điều chỉnh số instances theo tải thực tế:

```
Trigger: CPU > 70% trong 2 phút liên tiếp
  → Scale-out: desired 2 → 3
  → LB tự thêm instance mới vào rotation

Trigger: CPU < 30% trong 5 phút
  → Scale-in: desired 3 → 2
  → LB drain connections → xóa instance
```

Trong lab: script bash giám sát connections và trigger scale thủ công (tương đương CloudWatch Alarm).

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Benchmark baseline (2 backends)

```bash
echo "=== Baseline: 2 backends ==="
wrk -t2 -c50 -d20s --latency http://localhost/server-id | tee /tmp/bench-before.txt
grep "Requests/sec" /tmp/bench-before.txt
```

### 4.2 — Scale-out: tăng từ 2 → 3 instances

```bash
echo "=== Scale-out: desired 2 → 3 ==="

# Tạo instance mới (ASG spin up)
docker run -d \
  --name "app-3" \
  --network $APP_NETWORK \
  --ip 10.1.0.13 \
  -p 8083:80 \
  --label asg=$ASG_NAME \
  nginx:alpine \
  sh -c "
    echo 'app-3' > /usr/share/nginx/html/server-id
    echo 'healthy' > /usr/share/nginx/html/health
    nginx -g 'daemon off;'
  "

# Cập nhật LB config thêm instance mới (tương đương target group registration)
cat > /etc/nginx/conf.d/lb.conf << 'EOF'
upstream backend {
    least_conn;
    server localhost:8081 max_fails=3 fail_timeout=10s;
    server localhost:8082 max_fails=3 fail_timeout=10s;
    server localhost:8083 max_fails=3 fail_timeout=10s;
    keepalive 32;
}
server {
    listen 80 default_server;
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        add_header X-Served-By $upstream_addr always;
    }
    location /lb-health { return 200 "OK\n"; add_header Content-Type text/plain; }
    location /health    { proxy_pass http://backend/health; }
    location /server-id { proxy_pass http://backend/server-id; }
}
EOF

nginx -t && nginx -s reload
sleep 2

echo " 3 instances đang chạy:"
docker ps --filter "label=asg=$ASG_NAME" --format "table {{.Names}}\t{{.Status}}"
```

### 4.3 — So sánh throughput sau scale-out

```bash
echo "=== Benchmark: 3 backends ==="
wrk -t2 -c50 -d20s --latency http://localhost/server-id | tee /tmp/bench-after.txt

echo ""
echo "Requests/sec trước (2 backends): $(grep 'Requests/sec' /tmp/bench-before.txt | awk '{print $2}')"
echo "Requests/sec sau  (3 backends): $(grep 'Requests/sec' /tmp/bench-after.txt | awk '{print $2}')"
```

### 4.4 — Script Auto Scaling đơn giản

```bash
cat > /tmp/autoscale.sh << 'SCALER'
#!/bin/bash
# Auto Scaler — tương đương CloudWatch Alarm + ASG Policy
THRESHOLD_HIGH=80  # connections > 80 → scale out
THRESHOLD_LOW=10   # connections < 10 → scale in
CURRENT_DESIRED=$(docker ps --filter "label=asg=web-asg" -q | wc -l)
CURRENT_CONNS=$(ss -tn state established "dport = :8081 or dport = :8082 or dport = :8083" 2>/dev/null | wc -l)

echo "Instances hiện tại: $CURRENT_DESIRED | Connections: $CURRENT_CONNS"

if [ $CURRENT_CONNS -gt $THRESHOLD_HIGH ] && [ $CURRENT_DESIRED -lt 4 ]; then
  echo "  Scale-out: connections cao ($CURRENT_CONNS > $THRESHOLD_HIGH)"
elif [ $CURRENT_CONNS -lt $THRESHOLD_LOW ] && [ $CURRENT_DESIRED -gt 1 ]; then
  echo "  Scale-in: connections thấp ($CURRENT_CONNS < $THRESHOLD_LOW)"
else
  echo " Ổn định — không cần scale"
fi
SCALER

chmod +x /tmp/autoscale.sh
/tmp/autoscale.sh
```

### 4.5 — Dọn dẹp

```bash
# Xóa instances
for i in 1 2 3; do
  docker stop app-$i 2>/dev/null && docker rm app-$i 2>/dev/null
done

# Xóa network
docker network rm app-network 2>/dev/null

# Reset LB config
rm -f /etc/nginx/conf.d/lb.conf
nginx -s reload 2>/dev/null || true

echo " Dọn dẹp hoàn tất"
```

---

## Tổng kết

```
Bước 1: Instance template + khởi động 2 instances (desired=2)
Bước 2: Load Balancer (Nginx) + Health Check script
Bước 3: Kiểm thử phân phối + giả lập instance down
Bước 4: Scale-out 2→3, benchmark, auto-scale script

Trên Cloud:
  AWS   → Launch Template + ASG + ALB + CloudWatch Alarm
  GCP   → Instance Template + MIG + Cloud LB + Cloud Monitoring
  Azure → VM Scale Set + Azure LB + Azure Monitor
```

---

##  Bài tập

> Hoàn thành cleanup trên trước khi làm bài tập này.

**Yêu cầu:** Từ hai file benchmark `/tmp/bench-before.txt` và `/tmp/bench-after.txt`, tính và ghi ra file `/tmp/scaling-report.txt` với nội dung:

```
Scale-out Report
================
Backends before : 2
Backends after  : 3
RPS before      : XXXX
RPS after       : XXXX
Improvement     : XX%
Verdict         : Scale-out EFFECTIVE (nếu tăng >= 20%)
               hoặc Scale-out MARGINAL (nếu tăng < 20%)
```

**Gợi ý khi bí:**
- `grep "Requests/sec" /tmp/bench-before.txt | awk '{print $2}'` lấy số RPS
- Tính % cải thiện: `(after - before) / before * 100`
- Có thể dùng `python3 -c "..."` hoặc `bash` arithmetic

> Nhấn **Check** khi hoàn thành.
