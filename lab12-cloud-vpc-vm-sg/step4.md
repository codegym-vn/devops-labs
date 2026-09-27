# Bước 4: Kiểm thử và dọn dẹp tài nguyên

## Lý thuyết

Trên AWS thật, tài nguyên không dùng vẫn tính phí:

| Tài nguyên idle | ~Chi phí/tháng |
|----------------|----------------|
| EC2 t3.medium | $30 |
| ALB | $20 |
| NAT Gateway | $32 |
| Elastic IP chưa gắn | $3.6 |

> Thói quen tốt: luôn có cleanup script và đặt billing alert để phát hiện tài nguyên rò rỉ.

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Kiểm thử end-to-end

```bash
# VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID \
  --query 'Vpcs[0].{State:State,CIDR:CidrBlock}' --output table

# Security Group rules
aws ec2 describe-security-groups --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions[*].{Port:ToPort,Source:IpRanges[0].CidrIp}' \
  --output table

# HTTP test
echo "HTTP $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080)"

# Port 443 phải bị chặn
nc -z -w2 localhost 443 2>/dev/null && echo "OPEN" || echo "BLOCKED (đúng)"
```

### 4.2 — Dọn dẹp

```bash
# Container
docker stop web-server-1 && docker rm web-server-1
echo "✅ Container đã xóa"

# EC2 + Elastic IP
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 release-address --allocation-id $EIP_ID 2>/dev/null

# Network resources (theo thứ tự đúng)
sleep 3
aws ec2 delete-security-group --group-id $SG_ID
aws ec2 delete-subnet --subnet-id $SUBNET_ID
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
aws ec2 delete-vpc --vpc-id $VPC_ID

# Key Pair
aws ec2 delete-key-pair --key-name devops-keypair
rm -f ~/.ssh/devops-keypair.pem

echo ""
echo "✅ Dọn dẹp hoàn tất"
aws ec2 describe-vpcs \
  --filters "Name=cidr,Values=10.0.0.0/16" \
  --query 'length(Vpcs)' --output text | xargs -I{} echo "VPC còn lại: {} (phải là 0)"
```

---

## Tổng kết

```
Bước 1: VPC → Subnet → IGW → Route Table
Bước 2: Security Group (port 22 IP riêng, port 80 public)
Bước 3: EC2 + Key Pair + Docker container (web server thật)
Bước 4: End-to-end test + Cleanup
```
