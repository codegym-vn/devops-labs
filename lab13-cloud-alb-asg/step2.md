# Bước 2: Tạo Application Load Balancer và Target Group

## Lý thuyết

**ALB (Application Load Balancer)** hoạt động ở Layer 7 — hiểu nội dung HTTP, định tuyến theo path/header/host. Khác với **NLB** (Layer 4 — chỉ biết IP và port).

```
Client → ALB → Target Group → EC2
            ├── /api/*    → TG API
            └── default   → TG Web
```

**Target Group**: nhóm instances nhận traffic từ ALB.
- Health Check: ALB gọi `GET /health` mỗi 10s — instance phải trả 200 OK
- Instance fail → tạm loại khỏi rotation; phục hồi → tự động thêm lại
- **Connection Draining**: khi scale-in, ALB chờ connection hiện tại hoàn thành (mặc định 300s) trước khi ngắt

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Tạo ALB

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "web-alb" \
  --type application \
  --scheme internet-facing \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups $SG_ID \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "export ALB_ARN=$ALB_ARN" >> /tmp/lab-env.sh
echo "ALB: $ALB_DNS"
```

### 2.2 — Tạo Target Group

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name "web-tg" \
  --protocol HTTP --port 80 \
  --vpc-id $VPC_ID \
  --health-check-path "/health" \
  --health-check-interval-seconds 10 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "export TG_ARN=$TG_ARN" >> /tmp/lab-env.sh
echo "Target Group: $TG_ARN"
```

### 2.3 — Tạo Listener port 80

```bash
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --query 'Listeners[0].ListenerArn' --output text)

echo "export LISTENER_ARN=$LISTENER_ARN" >> /tmp/lab-env.sh
```

### 2.4 — Gắn ASG vào Target Group

```bash
aws autoscaling attach-load-balancer-target-groups \
  --auto-scaling-group-name $ASG_NAME \
  --target-group-arns $TG_ARN

echo "✅ ASG → Target Group"
```

### 2.5 — Khởi động 2 backend containers

```bash
for i in 1 2; do
  PORT=$((8080 + i))
  docker run -d --name "app-${i}" -p ${PORT}:80 nginx:alpine \
    sh -c "
      echo 'Server: app-${i}' > /usr/share/nginx/html/server-id
      echo 'healthy' > /usr/share/nginx/html/health
      nginx -g 'daemon off;'
    "
  echo "✅ app-${i} → port ${PORT}"
done

docker ps --filter "name=app-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2.6 — Cấu hình Nginx proxy (ALB thật)

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
        add_header         X-Served-By $upstream_addr always;
    }
    location /health   { proxy_pass http://backend/health; }
    location /server-id { proxy_pass http://backend/server-id; }
}
EOF

rm -f /etc/nginx/sites-enabled/default
nginx -t && nginx -s reload
echo "✅ Nginx ALB proxy sẵn sàng"
```

---

## Câu hỏi

1. Tại sao Health Check dùng `/health` thay vì `/`?
2. Connection Draining giải quyết vấn đề gì khi scale-in?
3. ALB có thể định tuyến theo tiêu chí nào ngoài path?
