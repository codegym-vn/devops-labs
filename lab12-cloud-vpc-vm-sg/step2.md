# Bước 2: Cấu hình Security Groups

## Lý thuyết

**Security Group** hoạt động như tường lửa ảo cấp instance:

| Đặc điểm | Security Group | Firewall truyền thống |
|-----------|---------------|----------------------|
| Trạng thái | **Stateful** — response tự động cho qua | Stateless — phải khai báo 2 chiều |
| Rule | Chỉ ALLOW, không có DENY | Cả ALLOW và DENY |
| Mặc định | Chặn tất cả inbound | Tuỳ cấu hình |

> **Nguyên tắc Least Privilege**: chỉ mở đúng port cần thiết, đúng nguồn cần thiết. Không bao giờ mở port 22 cho `0.0.0.0/0`.

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Tạo Security Group

```bash
SG_ID=$(aws ec2 create-security-group \
  --group-name "web-server-sg" \
  --description "SSH (IP riêng) + HTTP (public)" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

echo "export SG_ID=$SG_ID" >> /tmp/lab-env.sh
echo "SG: $SG_ID"
```

### 2.2 — Mở SSH từ IP của bạn

```bash
MY_IP=$(curl -s ifconfig.me)

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 22 --cidr ${MY_IP}/32

echo "✅ Port 22 → ${MY_IP}/32"
```

### 2.3 — Mở HTTP từ Internet

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

echo "✅ Port 80 → 0.0.0.0/0"
```

### 2.4 — Xem tất cả rules

```bash
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions[*].{Port:ToPort,Source:IpRanges[0].CidrIp}' \
  --output table
```

### 2.5 — Audit: thêm và thu hồi rule

```bash
# Thêm rule tạm
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Kiểm tra
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\`].FromPort" \
  --output text

# Port không cần thiết → thu hồi
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

echo "✅ Đã thu hồi port 443"
```

---

## Câu hỏi

1. Security Group "stateful" nghĩa là gì? Lợi thế so với Network ACL (stateless)?
2. Không khai báo Outbound rule — điều gì xảy ra với traffic đi ra?
3. Một instance có thể gắn bao nhiêu Security Group? Các rule có được merge không?
