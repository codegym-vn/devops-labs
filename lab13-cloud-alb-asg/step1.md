# Bước 1: Tạo Launch Template và Auto Scaling Group

## Thiết lập môi trường (chạy một lần)

```bash
# Cài AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# Cài LocalStack
pip3 install -q localstack

# Khởi động LocalStack
localstack start -d

echo "Đang chờ LocalStack..."
until curl -sf http://localhost:4566/_localstack/health | grep -q '"elasticloadbalancing": "available"'; do
  sleep 3; printf "."
done
echo " ✅ LocalStack sẵn sàng!"

alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Tạo VPC nền tảng
source /tmp/lab-env.sh 2>/dev/null || true
if [ -z "$VPC_ID" ]; then
  VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' --output text)
  SUBNET_1=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 --availability-zone ap-southeast-1a \
    --query 'Subnet.SubnetId' --output text)
  SUBNET_2=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 --availability-zone ap-southeast-1b \
    --query 'Subnet.SubnetId' --output text)
  IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' --output text)
  aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
  SG_ID=$(aws ec2 create-security-group \
    --group-name alb-sg --description "ALB + ASG SG" \
    --vpc-id $VPC_ID --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
  cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_1=$SUBNET_1
export SUBNET_2=$SUBNET_2
export IGW_ID=$IGW_ID
export SG_ID=$SG_ID
export ASG_NAME=web-asg
EOF
  echo "✅ VPC, Subnet, IGW, SG đã tạo xong"
fi
source /tmp/lab-env.sh
```

---

## Lý thuyết

**Launch Template** là blueprint định nghĩa cấu hình của mỗi EC2 instance được tạo ra — AMI, instance type, security group, user-data script. Khi Auto Scaling cần thêm instance, nó dùng Launch Template làm khuôn mẫu.

**Auto Scaling Group (ASG)** duy trì số lượng instance trong một khoảng min–max:

```
min=1 ──── desired=2 ──── max=4
  │              │              │
  └─ Không bao   └─ Số instance  └─ Không vượt
     giờ ít hơn    mặc định        quá số này
```

Khi CloudWatch Alarm kích hoạt:
- CPU > 70% → ASG tăng `desired` lên → tạo instance mới (scale-out)
- CPU < 30% → ASG giảm `desired` xuống → xóa instance (scale-in)

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 1.1 — Tạo Launch Template

```bash
# User-data script: mỗi instance tự cài Nginx và ghi tên server
USER_DATA=$(base64 -w0 << 'USERDATA'
#!/bin/bash
apt-get update -q && apt-get install -y -q nginx
SERVER_NAME=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || hostname)
cat > /var/www/html/index.html << HTML
<h1>Backend: ${SERVER_NAME}</h1>
HTML
echo "Server: ${SERVER_NAME}" > /var/www/html/server-id
systemctl start nginx
USERDATA
)

LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name "web-server-lt" \
  --version-description "v1 - Nginx web server" \
  --launch-template-data "{
    \"ImageId\": \"ami-0c55b159cbfafe1f0\",
    \"InstanceType\": \"t3.micro\",
    \"SecurityGroupIds\": [\"$SG_ID\"],
    \"UserData\": \"$USER_DATA\",
    \"TagSpecifications\": [{
      \"ResourceType\": \"instance\",
      \"Tags\": [
        {\"Key\": \"Name\", \"Value\": \"web-server\"},
        {\"Key\": \"Project\", \"Value\": \"devops-training\"}
      ]
    }]
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' --output text)

echo "Launch Template đã tạo: $LT_ID"
echo "export LT_ID=$LT_ID" >> /tmp/lab-env.sh
```

Kiểm tra Launch Template:
```bash
aws ec2 describe-launch-templates \
  --launch-template-names web-server-lt \
  --query 'LaunchTemplates[0].{ID:LaunchTemplateId,Name:LaunchTemplateName,Version:LatestVersionNumber}' \
  --output table
```

---

### 1.2 — Tạo Auto Scaling Group

```bash
ASG_NAME="web-asg"

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --launch-template "LaunchTemplateName=web-server-lt,Version=\$Default" \
  --min-size 1 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET_1,$SUBNET_2" \
  --health-check-type EC2 \
  --health-check-grace-period 30 \
  --tags "Key=Name,Value=web-asg,PropagateAtLaunch=true"

echo "export ASG_NAME=$ASG_NAME" >> /tmp/lab-env.sh
echo "✅ Auto Scaling Group '$ASG_NAME' đã tạo (min=1, desired=2, max=4)"
```

Xem trạng thái ASG:
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Min:MinSize,Desired:DesiredCapacity,Max:MaxSize,Status:Status}' \
  --output table
```

---

### 1.3 — Tạo Scaling Policies

```bash
# Policy scale-out: thêm 1 instance
SCALE_OUT_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name "scale-out-policy" \
  --scaling-adjustment 1 \
  --adjustment-type ChangeInCapacity \
  --cooldown 60 \
  --query 'PolicyARN' --output text)

# Policy scale-in: bớt 1 instance
SCALE_IN_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name "scale-in-policy" \
  --scaling-adjustment -1 \
  --adjustment-type ChangeInCapacity \
  --cooldown 120 \
  --query 'PolicyARN' --output text)

echo "export SCALE_OUT_ARN=$SCALE_OUT_ARN" >> /tmp/lab-env.sh
echo "export SCALE_IN_ARN=$SCALE_IN_ARN" >> /tmp/lab-env.sh
echo "✅ Scaling Policies đã tạo"
```

---

### 1.4 — Tạo CloudWatch Alarms kích hoạt scaling

```bash
# Alarm scale-out: CPU > 70% trong 2 phút liên tiếp
aws cloudwatch put-metric-alarm \
  --alarm-name "cpu-high-scale-out" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions $SCALE_OUT_ARN

# Alarm scale-in: CPU < 30% trong 5 phút liên tiếp
aws cloudwatch put-metric-alarm \
  --alarm-name "cpu-low-scale-in" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 60 \
  --evaluation-periods 5 \
  --threshold 30 \
  --comparison-operator LessThanThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions $SCALE_IN_ARN

echo "✅ CloudWatch Alarms đã cấu hình:"
aws cloudwatch describe-alarms \
  --alarm-names "cpu-high-scale-out" "cpu-low-scale-in" \
  --query 'MetricAlarms[*].{Alarm:AlarmName,Threshold:Threshold,Operator:ComparisonOperator}' \
  --output table
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao ASG cần trải instances ra **nhiều Availability Zone** thay vì chỉ 1 AZ?
2. **Cooldown period** trong Scaling Policy là gì? Tại sao scale-in cần cooldown dài hơn scale-out?
3. Sự khác biệt giữa `ChangeInCapacity` và `ExactCapacity` trong Scaling Policy?
