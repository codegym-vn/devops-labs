# Bước 3: Triển Khai Máy Ảo EC2 & Quản Lý SSH Key Pair

Trong bước này, bạn sẽ sử dụng **AWS CLI** để tạo cặp khóa xác thực **SSH Key Pair**, sau đó khởi chạy các máy ảo **EC2 (Elastic Compute Cloud)** vào đúng các Subnet và gắn Security Group tương ứng.

---

## 1. Lý Thuyết: Khởi Chạy Máy Ảo EC2 Chuẩn Doanh Nghiệp

Để khởi tạo một máy ảo EC2 trên AWS, bạn cần xác định 5 thông số cốt lõi:
1. **AMI (Amazon Machine Image):** Bản đóng gói hệ điều hành (Ubuntu, Amazon Linux, RedHat...). Trong LocalStack, bất kỳ ID nào dạng `ami-xxxx` đều hợp lệ.
2. **Instance Type:** Cấu hình phần cứng vCPU và RAM (ví dụ: `t2.micro` với 1 vCPU, 1GB RAM).
3. **Key Pair:** Cặp khóa SSH (Public Key nạp vào máy ảo, Private Key người dùng giữ). Tuyệt đối không dùng mật khẩu tĩnh để quản trị server Cloud.
4. **Subnet ID:** Vị trí đặt máy ảo:
   * Máy Web → Nằm trong `public-subnet`.
   * Máy DB → Nằm trong `private-subnet`.
5. **Security Group ID:** Gắn tường lửa tương ứng đã tạo ở Bước 2.

```
                  ┌────────────────────────────────────────┐
                  │          LỆNH RUN-INSTANCES            │
                  └──────────────────┬─────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
[ --image-id ami-xxx ]    [ --subnet-id subnet-xxx ]    [ --security-group-ids sg-xxx ]
   (Hệ điều hành)               (Vị trí mạng)                 (Tường lửa bảo vệ)
```

---

## 2. Thực Hành

Trước tiên, hãy tải lại các biến môi trường:

```bash
source /tmp/lab-env.sh
```{{exec}}

---

### 3.1 — Tạo SSH Key Pair

Tạo một Key Pair mới có tên `devops-key`, trích xuất Private Key (`KeyMaterial`) và lưu vào file `/tmp/devops-key.pem`:

```bash
aws ec2 create-key-pair \
  --key-name devops-key \
  --query 'KeyMaterial' \
  --output text > /tmp/devops-key.pem

# Khóa quyền file private key (600 hoặc 400 - chỉ owner được đọc)
chmod 400 /tmp/devops-key.pem

echo "✅ Đã tạo SSH Key Pair và lưu tại /tmp/devops-key.pem"
ls -la /tmp/devops-key.pem
```{{exec}}

---

### 3.2 — Triển Khai Web Server Vào Public Subnet

Khởi chạy máy ảo `web-server-1` gắn với `$PUB_SUBNET_ID` và nhóm bảo mật `$WEB_SG_ID`:

```bash
WEB_INST_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name devops-key \
  --security-group-ids $WEB_SG_ID \
  --subnet-id $PUB_SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ Web Server đã khởi chạy với Instance ID: $WEB_INST_ID"
echo "WEB_INST_ID=$WEB_INST_ID" >> /tmp/lab-env.sh
```{{exec}}

---

### 3.3 — Triển Khai Database Server Vào Private Subnet

Khởi chạy máy ảo `db-server-1` gắn với `$PRIV_SUBNET_ID` và nhóm bảo mật `$DB_SG_ID`:

```bash
DB_INST_ID=$(aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name devops-key \
  --security-group-ids $DB_SG_ID \
  --subnet-id $PRIV_SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=db-server-1}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ Database Server đã khởi chạy với Instance ID: $DB_INST_ID"
echo "DB_INST_ID=$DB_INST_ID" >> /tmp/lab-env.sh
```{{exec}}

---

### 3.4 — Truy Vấn Thông Tin & Giám Sát Trạng Thái Máy Ảo

Sử dụng cờ `--query` để lọc các thông số quan trọng (Tên, Trạng thái, IP nội bộ, Subnet):

```bash
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value | [0], InstanceId, State.Name, PrivateIpAddress, SubnetId]" \
  --output table
```{{exec}}

Quan sát bảng kết quả: Bạn sẽ thấy hai máy ảo đã được cấp phát địa chỉ IP nội bộ tương ứng với từng dải CIDR (`10.0.1.x` cho Web và `10.0.2.x` cho DB).

---

## 3. Bài Tập Thử Thách

> [!TIP]
> Hoàn thành các thao tác trên trước khi làm bài tập này.

**Yêu cầu:** Nhằm đáp ứng lưu lượng truy cập tăng đột biến, hệ thống cần bổ sung thêm một máy ảo Web Server thứ hai:
* Khởi chạy instance có tag `Name=web-server-2` vào **Public Subnet** (`$PUB_SUBNET_ID`).
* Sử dụng cùng cấu hình: AMI `ami-0c55b159cbfafe1f0`, instance type `t2.micro`, key `devops-key` và bảo vệ bằng Security Group `web-sg` (`$WEB_SG_ID`).

**Gợi ý lệnh:**
* Thực hiện tương tự lệnh ở mục **3.2**, chỉ cần đổi giá trị thẻ tag `Value=web-server-2`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
