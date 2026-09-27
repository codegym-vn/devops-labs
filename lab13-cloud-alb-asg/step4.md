# Bước 4: Scale-out và dọn dẹp

## Lý thuyết

Khi CloudWatch phát hiện CPU > 70% trong 2 chu kỳ liên tiếp:
1. Alarm kích hoạt Scaling Policy
2. ASG tăng `desired-capacity` → gọi `run-instances`
3. Instance mới khởi động, pass health check → ALB tự thêm vào rotation

Trên AWS thật, quá trình này mất 2–5 phút.

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Benchmark baseline (2 backends)

```bash
wrk -t4 -c100 -d20s --latency http://localhost/server-id | tee /tmp/bench-before.txt
grep "Requests/sec" /tmp/bench-before.txt
```

### 4.2 — Scale-out: desired 2 → 3

```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME --desired-capacity 3

docker run -d --name "app-3" -p 8083:80 nginx:alpine \
  sh -c "
    echo 'Server: app-3' > /usr/share/nginx/html/server-id
    echo 'healthy' > /usr/share/nginx/html/health
    nginx -g 'daemon off;'
  "
echo "✅ app-3 đã khởi động"

# Thêm app-3 vào Nginx upstream
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
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        add_header X-Served-By $upstream_addr always;
    }
    location /health    { proxy_pass http://backend/health; }
    location /server-id { proxy_pass http://backend/server-id; }
}
EOF
nginx -t && nginx -s reload
```

### 4.3 — So sánh throughput sau scale-out

```bash
wrk -t4 -c100 -d20s --latency http://localhost/server-id | tee /tmp/bench-after.txt

echo "Requests/sec trước: $(grep 'Requests/sec' /tmp/bench-before.txt | awk '{print $2}')"
echo "Requests/sec sau  : $(grep 'Requests/sec' /tmp/bench-after.txt | awk '{print $2}')"
```

### 4.4 — Dọn dẹp

```bash
# Containers
for i in 1 2 3; do docker stop app-$i && docker rm app-$i; done

# ALB resources
aws elbv2 delete-listener --listener-arn $LISTENER_ARN 2>/dev/null
aws elbv2 delete-target-group --target-group-arn $TG_ARN 2>/dev/null
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN 2>/dev/null

# ASG + Alarms
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME --force-delete 2>/dev/null
aws cloudwatch delete-alarms \
  --alarm-names "cpu-high-scale-out" "cpu-low-scale-in" 2>/dev/null
aws ec2 delete-launch-template --launch-template-id $LT_ID 2>/dev/null

# Network
aws ec2 delete-subnet --subnet-id $SUBNET_1 2>/dev/null
aws ec2 delete-subnet --subnet-id $SUBNET_2 2>/dev/null
aws ec2 detach-internet-gateway \
  --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 2>/dev/null
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID 2>/dev/null
aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null
aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null

rm -f /etc/nginx/conf.d/alb.conf && nginx -s reload 2>/dev/null || true
echo "✅ Dọn dẹp hoàn tất"
```
