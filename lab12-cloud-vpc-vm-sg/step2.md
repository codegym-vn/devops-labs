# Bước 2: Cấu hình Security Groups kiểm soát lưu lượng

## Lý thuyết

**Security Group** hoạt động như một **tường lửa ảo** bao quanh mỗi EC2 instance. Điểm khác biệt so với tường lửa truyền thống:

| Đặc điểm | Security Group | Traditional Firewall |
|-----------|---------------|---------------------|
| Trạng thái | **Stateful** — traffic trả về tự động cho qua | Stateless — phải khai báo 2 chiều |
| Áp dụng | Cấp instance (mỗi EC2 có thể có SG riêng) | Cấp network |
| Mặc định | **Chặn tất cả** inbound, **cho phép** tất cả outbound | Tuỳ cấu hình |
| Rule | Chỉ ALLOW — không có DENY rule | Cả ALLOW và DENY |

### Nguyên tắc Least Privilege

> Chỉ mở **đúng port cần thiết**, **đúng nguồn cần thiết**.
> Không bao giờ mở `0.0.0.0/0` cho SSH (port 22).

---

## Thử thách thực hành

Trước tiên, nạp lại biến môi trường từ Bước 1:

```bash
source /tmp/lab-env.sh
```

### 2.1 — Tạo Security Group

```bash
SG_ID=$(aws ec2 create-security-group \
  --group-name "web-server-sg" \
  --description "Security Group cho web server: SSH (IP riêng) + HTTP (public)" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=web-server-sg}]' \
  --query 'GroupId' \
  --output text)

echo "Security Group đã tạo: $SG_ID"

# Lưu vào lab-env
echo "export SG_ID=$SG_ID" >> /tmp/lab-env.sh
```

---

### 2.2 — Cho phép SSH từ địa chỉ IP của bạn

> ⚠️ Nguyên tắc bảo mật: **KHÔNG BAO GIỜ** mở port 22 cho `0.0.0.0/0` trên môi trường thực tế.

```bash
# Lấy IP hiện tại của bạn
MY_IP=$(curl -s ifconfig.me)
echo "IP của bạn: $MY_IP"

# Chỉ cho phép SSH từ đúng IP này
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32

echo "✅ Đã mở port 22 chỉ cho IP: ${MY_IP}/32"
```

---

### 2.3 — Cho phép HTTP từ Internet

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

echo "✅ Đã mở port 80 cho 0.0.0.0/0 (HTTP public)"
```

---

### 2.4 — Kiểm tra tất cả rules đã cấu hình

```bash
echo "=== Inbound Rules của Security Group $SG_ID ==="
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query 'SecurityGroups[0].IpPermissions[*].{Protocol:IpProtocol,FromPort:FromPort,ToPort:ToPort,Source:IpRanges[0].CidrIp}' \
  --output table
```

Kết quả mong đợi:
```
---------------------------------------------------
|           DescribeSecurityGroups                |
+----------+-----------+---------+----------------+
| FromPort | Protocol  | Source  |    ToPort      |
+----------+-----------+---------+----------------+
|  22      |  tcp      |  X.X.X.X/32  |  22      |
|  80      |  tcp      |  0.0.0.0/0   |  80      |
+----------+-----------+---------+----------------+
```

---

### 2.5 — Kiểm thử logic "chặn port"

Thêm một rule tạm để kiểm tra, sau đó xóa đi — mô phỏng quy trình audit:

```bash
# Thử thêm port 443 (HTTPS)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Kiểm tra: port 443 có trong danh sách?
aws ec2 describe-security-groups \
  --group-ids $SG_ID \
  --query "SecurityGroups[0].IpPermissions[?FromPort==\`443\`].FromPort" \
  --output text

# Kết luận: port không cần thiết → XÓA ngay
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

echo "✅ Đã thu hồi rule không cần thiết (port 443)"
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao Security Group được gọi là "stateful"? Điều này có lợi gì so với Network ACL (stateless)?
2. Nếu không khai báo Outbound rule nào, điều gì xảy ra với traffic từ EC2 instance đi ra ngoài?
3. Một instance có thể gắn bao nhiêu Security Group? Các rule có được tổng hợp (merge) lại không?
