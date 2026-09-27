# Bước 4: Giả lập Scale-out và dọn dẹp tài nguyên

## Lý thuyết: Scale-out trong thực tế

Khi CloudWatch phát hiện CPU > 70% trong 2 chu kỳ liên tiếp:
1. Alarm → kích hoạt Scaling Policy
2. ASG tăng `desired-capacity` lên 3
3. ASG gọi `run-instances` với Launch Template
4. EC2 instance mới khởi động, chạy `user-data` (cài Nginx)
5. Instance pass health check → ALB tự động thêm vào rotation

Toàn bộ quá trình mất **2-5 phút** trên AWS thật.

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Benchmark TRƯỚC khi scale (baseline)

```bash
echo "=== Baseline: 2 backends ==="
wrk -t4 -c100 -d20s --latency http://localhost/server-id 2>&1 | tee /tmp/bench-before.txt
echo ""
echo "Requests/sec TRƯỚC scale-out:"
grep "Requests/sec" /tmp/bench-before.txt
```

---

### 4.2 — Giả lập scale-out: tăng desired-capacity lên 3

```bash
echo "=== Scale-out: desired 2 → 3 ==="

# ASG API: tăng desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 3

echo "ASG desired capacity đã tăng lên 3"

# Mô phỏng instance mới được spin up bởi ASG
docker run -d \
  --name "app-3" \
  --label "aws-asg=web-asg" \
  --label "aws-target-group=web-tg" \
  -p 8083:80 \
  nginx:alpine \
  sh -c "
    echo 'Server: app-3 | Instance: i-000000000003 | AZ: ap-southeast-1b' \
      > /usr/share/nginx/html/server-id
    echo 'healthy' > /usr/share/nginx/html/health
    nginx -g 'daemon off;'
  "

echo "✅ app-3 khởi động thành công (mô phỏng instance mới của ASG)"

# Cập nhật Nginx upstream thêm app-3
cat > /etc/nginx/conf.d/alb.conf << 'EOF'
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
        proxy_pass         http://backend;
        proxy_http_version 1.1;
        proxy_set_header   Connection "";
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        add_header         X-Served-By $upstream_addr always;
    }
    location /health  { proxy_pass http://backend/health; }
    location /server-id { proxy_pass http://backend/server-id; }
}
EOF

nginx -t && nginx -s reload
echo "✅ Nginx đã thêm app-3 vào upstream"
```

---

### 4.3 — Kiểm tra phân phối sau scale-out

```bash
echo "=== Phân phối sau scale-out (3 backends) ==="
declare -A COUNT2
for i in $(seq 1 30); do
  SRV=$(curl -s http://localhost/server-id | grep -oP 'app-\d+')
  COUNT2[$SRV]=$((${COUNT2[$SRV]:-0} + 1))
done

for SRV in app-1 app-2 app-3; do
  N=${COUNT2[$SRV]:-0}
  PCT=$(( N * 100 / 30 ))
  BAR=$(printf '█%.0s' $(seq 1 $((PCT / 3))))
  printf "  %-8s: %2d/30 (%2d%%) %s\n" "$SRV" "$N" "$PCT" "$BAR"
done

echo ""
echo "=== Benchmark SAU scale-out (3 backends) ==="
wrk -t4 -c100 -d20s --latency http://localhost/server-id 2>&1 | tee /tmp/bench-after.txt

echo ""
echo "So sánh Requests/sec:"
echo -n "  Trước (2 backends): "; grep "Requests/sec" /tmp/bench-before.txt | awk '{print $2}'
echo -n "  Sau   (3 backends): "; grep "Requests/sec" /tmp/bench-after.txt | awk '{print $2}'
```

---

### 4.4 — Dọn dẹp toàn bộ tài nguyên

```bash
echo "=== Bắt đầu dọn dẹp ==="

# Xóa Docker containers
for i in 1 2 3; do
  docker stop app-$i 2>/dev/null && docker rm app-$i 2>/dev/null && echo "✅ Đã xóa app-$i"
done

# Xóa Listener, Target Group, ALB
aws elbv2 delete-listener --listener-arn $LISTENER_ARN 2>/dev/null
aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>/dev/null
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN 2>/dev/null
echo "✅ Đã xóa ALB, Listener, Target Group"

# Xóa ASG, Scaling Policies, CloudWatch Alarms
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME --force-delete 2>/dev/null
aws cloudwatch delete-alarms --alarm-names "cpu-high-scale-out" "cpu-low-scale-in" 2>/dev/null
echo "✅ Đã xóa ASG và CloudWatch Alarms"

# Xóa Launch Template
aws ec2 delete-launch-template --launch-template-id $LT_ID 2>/dev/null
echo "✅ Đã xóa Launch Template"

# Xóa network resources
aws ec2 delete-subnet --subnet-id $SUBNET_1 2>/dev/null
aws ec2 delete-subnet --subnet-id $SUBNET_2 2>/dev/null
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>/dev/null
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null
aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null
aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null
echo "✅ Đã xóa VPC và network resources"

# Reset Nginx
rm -f /etc/nginx/conf.d/alb.conf
nginx -s reload 2>/dev/null || true

echo ""
echo "🎉 Dọn dẹp hoàn tất!"
```
