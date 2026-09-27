# Bước 2: Tạo Application Load Balancer và Target Group

## Lý thuyết

**Application Load Balancer (ALB)** hoạt động ở **Layer 7 (HTTP/HTTPS)** — nó hiểu nội dung request và có thể định tuyến theo path, header, host. Khác với **Network Load Balancer** (Layer 4 — chỉ biết IP và port).

```
Client → ALB (Layer 7) → Target Group → EC2 Instances
                  │
                  ├── Rule 1: /api/*   → Target Group API
                  ├── Rule 2: /static/* → Target Group CDN
                  └── Default          → Target Group Web
```

**Target Group** là nhóm các instance nhận traffic từ ALB:
- **Health Check**: ALB định kỳ gọi `GET /health` → instance phải trả về 200 OK
- Instance không pass health check sẽ bị **tạm thời loại** khỏi rotation
- Khi instance phục hồi → tự động đưa trở lại

**Connection Draining (Deregistration Delay)**: Khi một instance bị scale-in, ALB chờ các connection hiện tại hoàn thành (mặc định 300s) trước khi ngắt hẳn.

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Tạo Application Load Balancer

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "web-alb" \
  --type application \
  --scheme internet-facing \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups $SG_ID \
  --tags Key=Name,Value=web-alb Key=Project,Value=devops-training \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "ALB ARN : $ALB_ARN"
echo "ALB DNS : $ALB_DNS"

echo "export ALB_ARN=$ALB_ARN" >> /tmp/lab-env.sh
echo "export ALB_DNS=$ALB_DNS" >> /tmp/lab-env.sh
```

---

### 2.2 — Tạo Target Group với Health Check

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name "web-tg" \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --health-check-protocol HTTP \
  --health-check-path "/health" \
  --health-check-interval-seconds 10 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: $TG_ARN"
echo "export TG_ARN=$TG_ARN" >> /tmp/lab-env.sh
```

Xem cấu hình Health Check:
```bash
aws elbv2 describe-target-groups \
  --target-group-arns $TG_ARN \
  --query 'TargetGroups[0].{Name:TargetGroupName,Port:Port,HealthPath:HealthCheckPath,Interval:HealthCheckIntervalSeconds}' \
  --output table
```

---

### 2.3 — Tạo Listener và gắn vào Target Group

```bash
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "Listener ARN: $LISTENER_ARN"
echo "export LISTENER_ARN=$LISTENER_ARN" >> /tmp/lab-env.sh
```

---

### 2.4 — Gắn ASG vào Target Group

```bash
aws autoscaling attach-load-balancer-target-groups \
  --auto-scaling-group-name $ASG_NAME \
  --target-group-arns $TG_ARN

echo "✅ ASG đã gắn vào Target Group"
```

---

### 2.5 — Khởi động Docker containers đóng vai EC2 instances

```bash
# Tạo 2 backend containers (tương ứng desired-capacity = 2)
for i in 1 2; do
  PORT=$((8080 + i))

  docker run -d \
    --name "app-${i}" \
    --label "aws-asg=web-asg" \
    --label "aws-target-group=web-tg" \
    -p ${PORT}:80 \
    nginx:alpine \
    sh -c "
      mkdir -p /var/www/html
      echo 'Server: app-${i} | Instance: i-00000000000${i} | AZ: ap-southeast-1a' \
        > /usr/share/nginx/html/server-id
      echo 'healthy' > /usr/share/nginx/html/health
      nginx -g 'daemon off;'
    "

  echo "✅ app-${i} đang chạy trên port ${PORT}"
done

docker ps --filter "name=app-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

### 2.6 — Cấu hình Nginx làm ALB proxy thật

```bash
cat > /etc/nginx/conf.d/alb.conf << 'EOF'
upstream backend {
    least_conn;
    server localhost:8081;
    server localhost:8082;
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
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
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

# Xóa default config mặc định
rm -f /etc/nginx/sites-enabled/default

nginx -t && nginx -s reload
echo "✅ Nginx ALB proxy đã cấu hình và reload"
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao Health Check path nên là `/health` thay vì `/`? Những thông tin gì nên trả về trong health check response?
2. **Connection Draining** giúp gì khi scale-in một instance đang xử lý request?
3. ALB có thể định tuyến theo những tiêu chí nào ngoài round-robin? Cho ví dụ use case thực tế.
