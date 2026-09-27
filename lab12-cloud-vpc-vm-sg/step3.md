# Bước 3: Triển khai EC2 và kết nối SSH

## Lý thuyết

**EC2** là máy ảo của AWS, tạo từ **AMI** (blueprint chứa OS và cấu hình gốc).

Vòng đời instance:
```
run-instances → [pending] → [running] → [stopping] → [stopped] → [terminated]
```

**Key Pair** — xác thực SSH bằng mã hóa bất đối xứng:
- **Private key** (.pem): bạn giữ, không chia sẻ
- **Public key**: AWS lưu vào `~/.ssh/authorized_keys` trong instance

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 3.1 — Tạo Key Pair

```bash
aws ec2 create-key-pair \
  --key-name devops-keypair \
  --key-type ed25519 \
  --query 'KeyMaterial' --output text > ~/.ssh/devops-keypair.pem

chmod 400 ~/.ssh/devops-keypair.pem
echo "✅ Key Pair tạo xong: $(ls -la ~/.ssh/devops-keypair.pem)"
```

### 3.2 — Đăng ký EC2 Instance

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id $SUBNET_ID \
  --security-group-ids $SG_ID \
  --key-name devops-keypair \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1},{Key=Environment,Value=lab}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "export INSTANCE_ID=$INSTANCE_ID" >> /tmp/lab-env.sh
echo "Instance: $INSTANCE_ID"

aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].{State:State.Name,Type:InstanceType,SG:SecurityGroups[0].GroupId}' \
  --output table
```

### 3.3 — Khởi động web server bằng Docker

LocalStack mô phỏng EC2 API — không chạy OS thật. Docker container đóng vai instance:

```bash
cat > /tmp/nginx.conf << 'EOF'
server {
    listen 80;
    location / {
        return 200 "Server: web-server-1\n";
        add_header Content-Type text/plain;
    }
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

docker run -d \
  --name web-server-1 \
  --label ec2-instance-id=$INSTANCE_ID \
  -p 8080:80 \
  -v /tmp/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:alpine

echo "✅ Container chạy trên port 8080"
```

### 3.4 — SSH vào instance

```bash
# AWS thật: ssh -i ~/.ssh/devops-keypair.pem ubuntu@<PUBLIC_IP>

# Trong lab — docker exec tương đương SSH:
docker exec -it web-server-1 sh
# hostname / ip addr show / exit
```

### 3.5 — Kiểm thử HTTP

```bash
curl http://localhost:8080
curl http://localhost:8080/health
curl -w "\nResponse time: %{time_total}s\n" -o /dev/null -s http://localhost:8080
```

### 3.6 — Gán Elastic IP

```bash
EIP=$(aws ec2 allocate-address --domain vpc \
  --query 'AllocationId' --output text)

aws ec2 associate-address \
  --instance-id $INSTANCE_ID --allocation-id $EIP

echo "Elastic IP $EIP → $INSTANCE_ID"
echo "export EIP_ID=$EIP" >> /tmp/lab-env.sh
```

---

## Câu hỏi

1. Tại sao phải `chmod 400` file `.pem`?
2. Sự khác biệt giữa `stop` và `terminate` một EC2 instance?
3. Tại sao Public IP mặc định của EC2 thay đổi sau mỗi lần restart?
