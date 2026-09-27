# Bước 3: Triển khai máy ảo EC2 và kết nối SSH

## Lý thuyết

**EC2 (Elastic Compute Cloud)** là dịch vụ máy ảo của AWS. Mỗi instance được tạo từ một **AMI (Amazon Machine Image)** — blueprint chứa OS và cấu hình gốc.

Vòng đời của một EC2 instance:

```
         aws ec2 run-instances
               │
               ▼
         [pending]  ──── Đang khởi động
               │
               ▼
         [running]  ──── Sẵn sàng dùng
               │
       ┌───────┴───────┐
       ▼               ▼
  [stopping]       [rebooting]
       │
       ▼
  [stopped]  ──── Tắt, không tính phí compute
       │
       ▼
  [terminated]  ──── Xóa vĩnh viễn, không thể khôi phục
```

**Key Pair** là cặp khóa mã hóa bất đối xứng để xác thực SSH:
- **Private key** (.pem): Bạn giữ, không chia sẻ với ai
- **Public key**: AWS lưu vào `~/.ssh/authorized_keys` trong instance

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 3.1 — Tạo Key Pair Ed25519

```bash
# Tạo Key Pair và lưu private key
aws ec2 create-key-pair \
  --key-name devops-keypair \
  --key-type ed25519 \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/devops-keypair.pem

# Phân quyền private key (bắt buộc, SSH từ chối nếu quyền quá rộng)
chmod 400 ~/.ssh/devops-keypair.pem

echo "✅ Key Pair đã tạo:"
ls -la ~/.ssh/devops-keypair.pem
```

---

### 3.2 — Đăng ký EC2 Instance (AWS API)

Lệnh `run-instances` đăng ký instance với AWS — trong môi trường thật, AWS sẽ cấp phát phần cứng và khởi động VM:

```bash
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id $SUBNET_ID \
  --security-group-ids $SG_ID \
  --key-name devops-keypair \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1},{Key=Project,Value=devops-training},{Key=Environment,Value=lab}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance đã đăng ký: $INSTANCE_ID"
echo "export INSTANCE_ID=$INSTANCE_ID" >> /tmp/lab-env.sh
```

Kiểm tra trạng thái instance:

```bash
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].{ID:InstanceId,State:State.Name,Type:InstanceType,Subnet:SubnetId,SG:SecurityGroups[0].GroupId}' \
  --output table
```

---

### 3.3 — Khởi động máy ảo thật bằng Docker

Trong LocalStack, EC2 instance là API — không chạy OS thật. Docker container đóng vai instance đang hoạt động:

```bash
# Tạo custom Nginx image trả về thông tin server
cat > /tmp/nginx-server.conf << 'EOF'
server {
    listen 80;
    location / {
        return 200 "EC2 Instance: web-server-1\nInstance ID: $INSTANCE_ID\nRegion: ap-southeast-1\n";
        add_header Content-Type text/plain;
    }
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Chạy container mô phỏng EC2 instance
docker run -d \
  --name web-server-1 \
  --label ec2-instance-id=$INSTANCE_ID \
  --label ec2-name=web-server-1 \
  -p 8080:80 \
  -v /tmp/nginx-server.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:alpine

echo "✅ Container 'web-server-1' đang chạy trên port 8080"
docker ps --filter "name=web-server-1" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

### 3.4 — Kết nối SSH vào "instance"

Trong môi trường thật, bạn SSH qua Public IP. Ở đây, `docker exec` tương đương SSH:

```bash
# SSH thật (môi trường AWS)
# ssh -i ~/.ssh/devops-keypair.pem ubuntu@<PUBLIC_IP>

# Tương đương trong lab (docker exec = SSH vào container)
docker exec -it web-server-1 sh

# Bên trong "instance", chạy các lệnh khám phá:
# hostname
# ip addr show
# ps aux
# cat /etc/nginx/conf.d/default.conf
# exit
```

---

### 3.5 — Kiểm thử HTTP từ bên ngoài

```bash
# Kiểm tra server phản hồi
curl http://localhost:8080
echo ""

# Kiểm tra health endpoint
curl http://localhost:8080/health

# Đo response time
curl -w "\nThời gian phản hồi: %{time_total}s\n" -o /dev/null -s http://localhost:8080
```

---

### 3.6 — Gán Elastic IP (Public IP) vào Instance

Trong AWS thật, instance cần Elastic IP để có địa chỉ IP cố định:

```bash
# Cấp phát Elastic IP
EIP=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

# Gắn vào instance
aws ec2 associate-address \
  --instance-id $INSTANCE_ID \
  --allocation-id $EIP

echo "Elastic IP $EIP đã gắn vào $INSTANCE_ID"
echo "export EIP_ID=$EIP" >> /tmp/lab-env.sh
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao phải `chmod 400` file private key `.pem` trước khi dùng SSH?
2. Sự khác biệt giữa `stop` và `terminate` một EC2 instance?
3. Elastic IP là gì? Tại sao Public IP mặc định của EC2 thay đổi sau mỗi lần restart?
