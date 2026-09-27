# Bước 4: Kiểm thử toàn bộ hạ tầng và dọn dẹp tài nguyên

## Lý thuyết: Tại sao dọn dẹp tài nguyên quan trọng?

Trên AWS thật, tài nguyên không dùng vẫn **tính phí**. Đây là lỗi FinOps phổ biến nhất:

| Tài nguyên quên xóa | Chi phí/tháng ước tính |
|--------------------|-----------------------|
| EC2 t3.medium idle | ~$30 |
| ALB không có traffic | ~$20 |
| NAT Gateway idle | ~$32 |
| Elastic IP chưa gắn | ~$3.6 |

> 💡 **Thói quen tốt**: Luôn có `cleanup.sh` cho mỗi lab. Ngay cả kỹ sư senior cũng đặt **billing alert** để phát hiện tài nguyên rò rỉ.

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Kiểm thử toàn bộ luồng kết nối

Mô phỏng luồng từ Internet → IGW → VPC → Subnet → Security Group → Instance:

```bash
echo "=== Kiểm thử toàn bộ hạ tầng ==="
echo ""

# Kiểm tra VPC
VPC_STATE=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
  --query 'Vpcs[0].State' --output text)
echo "1. VPC ($VPC_ID): $VPC_STATE"

# Kiểm tra Subnet
SUBNET_STATE=$(aws ec2 describe-subnets --subnet-ids $SUBNET_ID \
  --query 'Subnets[0].State' --output text)
echo "2. Subnet ($SUBNET_ID): $SUBNET_STATE"

# Kiểm tra IGW
IGW_STATE=$(aws ec2 describe-internet-gateways \
  --internet-gateway-ids $IGW_ID \
  --query 'InternetGateways[0].Attachments[0].State' --output text)
echo "3. Internet Gateway ($IGW_ID): $IGW_STATE"

# Kiểm tra Security Group rules
echo "4. Security Group ($SG_ID) — Inbound Rules:"
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions[*].{Port:ToPort,Source:IpRanges[0].CidrIp}' \
  --output table

# Kiểm tra Instance
echo "5. EC2 Instance ($INSTANCE_ID):"
aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].{State:State.Name,Type:InstanceType,SG:SecurityGroups[0].GroupName}' \
  --output table

# Kiểm tra HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
echo "6. HTTP Test (port 8080): $HTTP_CODE"

# Kiểm tra port bị chặn
NC_RESULT=$(nc -z -w2 localhost 443 2>/dev/null && echo "OPEN" || echo "BLOCKED")
echo "7. Port 443 (không mở trong SG): $NC_RESULT"
```

---

### 4.2 — Tạo báo cáo tổng kết hạ tầng

```bash
cat << EOF
╔═══════════════════════════════════════════════════════╗
║           BÁO CÁO HẠ TẦNG VPC LAB                    ║
╠═══════════════════════════════════════════════════════╣
║ VPC ID       : $VPC_ID
║ VPC CIDR     : 10.0.0.0/16
║ Subnet       : $SUBNET_ID (10.0.1.0/24)
║ IGW          : $IGW_ID
║ Security Group: $SG_ID
║              : Port 22 — SSH (IP riêng)
║              : Port 80 — HTTP (public)
║ Instance     : $INSTANCE_ID (t3.micro)
╠═══════════════════════════════════════════════════════╣
║ Trạng thái   : ✅ Hoạt động bình thường               ║
╚═══════════════════════════════════════════════════════╝
EOF
```

---

### 4.3 — Dọn dẹp tài nguyên (Cleanup Script)

Đây là kỹ năng bắt buộc trên môi trường thật để tránh phí phát sinh:

```bash
echo "=== Bắt đầu dọn dẹp tài nguyên ==="

# 1. Dừng và xóa container Docker
docker stop web-server-1 && docker rm web-server-1
echo "✅ Đã xóa container"

# 2. Terminate EC2 instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
echo "✅ Đã terminate instance $INSTANCE_ID"

# 3. Giải phóng Elastic IP
aws ec2 release-address --allocation-id $EIP_ID 2>/dev/null && echo "✅ Đã giải phóng Elastic IP" || echo "  (bỏ qua)"

# 4. Xóa Security Group (sau khi instance đã terminate)
sleep 3
aws ec2 delete-security-group --group-id $SG_ID
echo "✅ Đã xóa Security Group"

# 5. Xóa Subnet
aws ec2 delete-subnet --subnet-id $SUBNET_ID
echo "✅ Đã xóa Subnet"

# 6. Gỡ và xóa Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
echo "✅ Đã gỡ và xóa Internet Gateway"

# 7. Xóa VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "✅ Đã xóa VPC"

# 8. Xóa Key Pair
aws ec2 delete-key-pair --key-name devops-keypair
rm -f ~/.ssh/devops-keypair.pem
echo "✅ Đã xóa Key Pair"

echo ""
echo "🎉 Dọn dẹp hoàn tất — Không còn tài nguyên nào hoạt động"

# Xác nhận: không còn VPC nào với CIDR này
REMAINING=$(aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'length(Vpcs)' --output text)
echo "VPC còn lại: $REMAINING (phải là 0)"
```

---

## Tổng kết những gì đã làm

```
Bước 1: VPC 10.0.0.0/16 → Subnet 10.0.1.0/24 → IGW → Route Table
           (Xây dựng mạng ảo riêng với đường ra Internet)
           ↓
Bước 2: Security Group → Port 22 (SSH, IP riêng) + Port 80 (HTTP, public)
           (Kiểm soát traffic: chỉ cho phép đúng những gì cần thiết)
           ↓
Bước 3: EC2 t3.micro + Key Pair Ed25519 → Docker container (web server thật)
           (Triển khai máy ảo với xác thực SSH chuẩn)
           ↓
Bước 4: Kiểm thử end-to-end → Cleanup script (thói quen FinOps)
           (Xác nhận hạ tầng hoạt động đúng và dọn dẹp sau lab)
```
