#  Chúc mừng! Bạn đã hoàn thành Lab: Cloud VPC + VM + Security Groups

## Những gì bạn đã làm được

Bạn vừa tự tay xây dựng một hạ tầng Cloud chuẩn từ đầu:

```
 Bước 1 — Hạ tầng mạng
   VPC (10.0.0.0/16) → Subnet public (10.0.1.0/24)
   → Internet Gateway → Route Table (0.0.0.0/0 → IGW)

 Bước 2 — Bảo mật
   Security Group: SSH chỉ từ IP riêng, HTTP từ public
   Áp dụng nguyên tắc Least Privilege

 Bước 3 — Triển khai
   EC2 instance + Key Pair Ed25519
   Web server Nginx hoạt động thật (qua Docker)

 Bước 4 — Vận hành
   Kiểm thử end-to-end toàn bộ luồng
   Cleanup script dọn sạch tài nguyên
```

---

## Bảng tra cứu nhanh (Cheat Sheet)

### VPC & Networking
```bash
# Tạo VPC
aws ec2 create-vpc --cidr-block <CIDR>

# Tạo Subnet
aws ec2 create-subnet --vpc-id <VPC> --cidr-block <CIDR> --availability-zone <AZ>

# Tạo và gắn Internet Gateway
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --internet-gateway-id <IGW> --vpc-id <VPC>

# Thêm route ra Internet
aws ec2 create-route --route-table-id <RTB> --destination-cidr-block 0.0.0.0/0 --gateway-id <IGW>
```

### Security Groups
```bash
# Tạo Security Group
aws ec2 create-security-group --group-name <NAME> --description <DESC> --vpc-id <VPC>

# Thêm inbound rule
aws ec2 authorize-security-group-ingress \
  --group-id <SG> --protocol tcp --port <PORT> --cidr <CIDR>

# Xóa inbound rule
aws ec2 revoke-security-group-ingress \
  --group-id <SG> --protocol tcp --port <PORT> --cidr <CIDR>

# Xem tất cả rules
aws ec2 describe-security-groups --group-ids <SG> \
  --query 'SecurityGroups[0].IpPermissions' --output table
```

### EC2 Instance
```bash
# Tạo Key Pair Ed25519
aws ec2 create-key-pair --key-name <NAME> --key-type ed25519 \
  --query 'KeyMaterial' --output text > key.pem
chmod 400 key.pem

# Khởi động instance
aws ec2 run-instances \
  --image-id <AMI> --instance-type t3.micro \
  --subnet-id <SUBNET> --security-group-ids <SG> --key-name <KEYPAIR>

# Kiểm tra trạng thái
aws ec2 describe-instances --instance-ids <INSTANCE>

# Terminate instance
aws ec2 terminate-instances --instance-ids <INSTANCE>

# SSH vào instance
ssh -i key.pem ubuntu@<PUBLIC_IP>
```

---

## Kết nối với các bài học tiếp theo

| Lab tiếp theo | Xây dựng trên nền tảng này |
|--------------|--------------------------|
| **Lab 8: ALB + Auto Scaling** | Thêm Load Balancer trước instances, tự động scale khi tải tăng |
| **Lab 12: FinOps** | Gắn Tags lên VPC, Subnet, Instance để theo dõi và tối ưu chi phí |
| **Terraform (Topic 2)** | Viết toàn bộ hạ tầng vừa tạo thủ công vào code `.tf` — tái sử dụng, version control |

---

## Tự kiểm tra kiến thức

- [ ] Giải thích được sự khác biệt giữa VPC, Subnet, Security Group và NACL
- [ ] Biết vẽ sơ đồ luồng traffic từ Internet đến EC2 instance
- [ ] Tự tạo VPC + EC2 không nhìn tài liệu trong < 10 phút
- [ ] Giải thích được tại sao Security Group là "stateful"
- [ ] Biết cách audit và revoke security group rule không cần thiết
