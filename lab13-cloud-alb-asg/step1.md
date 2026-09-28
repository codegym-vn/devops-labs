# Bước 1: Tạo Launch Template và Kích Hoạt Auto Scaling Group

Trong bước này, bạn sẽ sử dụng **AWS CLI** để tạo bản thiết kế máy chủ (**Launch Template**) và khởi tạo **Auto Scaling Group (ASG)** duy trì 2 máy ảo chạy song song.

---

## 1. Lý Thuyết: Launch Template & Auto Scaling Group

* **Launch Template:** Thay vì mỗi lần tạo máy ảo bạn phải gõ lại AMI, Instance Type, Key Pair và User Data script, bạn đóng gói tất cả vào một Template duy nhất có hỗ trợ versioning.
* **Auto Scaling Group (ASG):**
  * `min-size = 1`: Số máy ảo tối thiểu cho phép (không bao giờ giảm xuống dưới mức này).
  * `max-size = 4`: Số máy ảo tối đa được phép mở rộng khi tải tăng đỉnh điểm (giới hạn trần để tránh vỡ ngân sách).
  * `desired-capacity = 2`: Số máy ảo hệ thống luôn cố gắng duy trì ở trạng thái bình thường.

---

## 2. Thực Hành

Trước tiên, hãy tải các thông số mạng (VPC và 2 Subnets đa vùng) đã được chuẩn bị sẵn:

```bash
source /tmp/lab-env.sh
echo "VPC: $VPC_ID"
echo "Subnet 1 (us-east-1a): $SUBNET_1"
echo "Subnet 2 (us-east-1b): $SUBNET_2"
```{{exec}}

---

### 1.1 — Tạo Security Groups Cho ALB và Backend Instances

Theo nguyên tắc phân tách trách nhiệm (Separation of Concerns):
1. **`alb-sg`:** Nhận traffic HTTP cổng 80 từ toàn bộ người dùng Internet (`0.0.0.0/0`).
2. **`app-sg`:** Chỉ chấp nhận traffic cổng 80 từ chính `alb-sg` (không ai được gọi trực tiếp vào máy chủ backend).

```bash
# 1. Tạo Security Group cho ALB
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name "alb-sg" \
  --description "Security group cho Application Load Balancer" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

echo "ALB_SG_ID=$ALB_SG_ID" >> /tmp/lab-env.sh
echo "✅ Đã tạo alb-sg: $ALB_SG_ID"

# 2. Tạo Security Group cho Backend Instances
APP_SG_ID=$(aws ec2 create-security-group \
  --group-name "app-sg" \
  --description "Security group cho Backend EC2 Instances" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $APP_SG_ID --protocol tcp --port 80 --source-group $ALB_SG_ID

echo "APP_SG_ID=$APP_SG_ID" >> /tmp/lab-env.sh
echo "✅ Đã tạo app-sg: $APP_SG_ID"
```{{exec}}

---

### 1.2 — Chuẩn Bị User Data Script & Tạo Launch Template

User Data script sẽ tự động cài đặt và khởi động Web Server khi mỗi máy ảo trong ASG được bật:

```bash
# 1. Tạo script User Data
cat << 'EOF' > /tmp/user-data.sh
#!/bin/bash
echo "Hello from EC2 Auto Scaling Instance: $(hostname)" > /var/www/html/index.html
echo "healthy" > /var/www/html/health
EOF

# Mã hóa User Data sang chuẩn Base64 (AWS yêu cầu)
USER_DATA_B64=$(base64 -w 0 /tmp/user-data.sh 2>/dev/null || base64 /tmp/user-data.sh)

# 2. Tạo file JSON cấu hình Launch Template Data
cat << EOF > /tmp/lt-data.json
{
  "ImageId": "ami-0c55b159cbfafe1f0",
  "InstanceType": "t2.micro",
  "SecurityGroupIds": ["$APP_SG_ID"],
  "UserData": "$USER_DATA_B64",
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [{"Key": "Name", "Value": "asg-web-worker"}]
    }
  ]
}
EOF

# 3. Tạo Launch Template
aws ec2 create-launch-template \
  --launch-template-name "web-launch-template" \
  --version-description "v1-production" \
  --launch-template-data file:///tmp/lt-data.json

echo "✅ Đã tạo Launch Template 'web-launch-template' thành công!"
```{{exec}}

---

### 1.3 — Khởi Tạo Auto Scaling Group (`web-asg`)

Kích hoạt Auto Scaling Group liên kết với `web-launch-template`, trải rộng trên cả 2 Subnets (`$SUBNET_1,$SUBNET_2`) để bảo đảm tính sẵn sàng cao:

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "web-asg" \
  --launch-template "LaunchTemplateName=web-launch-template,Version=\$Latest" \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET_1,$SUBNET_2"

echo "✅ Đã kích hoạt Auto Scaling Group 'web-asg' (Desired: 2)!"
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP]
> ASG sẽ tự động sinh ra 2 máy ảo EC2 mới theo `desired-capacity=2`.

**Yêu cầu:** Hãy kiểm tra xem Auto Scaling Group đã tạo ra bao nhiêu máy ảo và xem ID của các máy ảo đó:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query 'AutoScalingGroups[0].Instances[].[InstanceId, LifecycleState, HealthStatus]' \
  --output table
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
