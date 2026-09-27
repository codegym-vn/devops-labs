# Bước 1: Tạo Launch Template và Auto Scaling Group

## Thiết lập môi trường

```bash
# Cài AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# Khởi động LocalStack
docker run -d --rm --name localstack \
  -p 4566:4566 \
  -e SERVICES=ec2,elbv2,autoscaling,cloudwatch,budgets \
  localstack/localstack:3.8

echo "Chờ LocalStack..."
until curl -sf http://localhost:4566/_localstack/health | grep -q '"elasticloadbalancing"'; do
  sleep 3; printf "."
done
echo " ✅ Sẵn sàng!"

alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Tạo VPC nền tảng
source /tmp/lab-env.sh 2>/dev/null || true
if [ -z "$VPC_ID" ]; then
  VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
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
    --group-name alb-sg --description "ALB SG" \
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
  echo "✅ VPC + Subnet + IGW + SG sẵn sàng"
fi
source /tmp/lab-env.sh
```

---

## Lý thuyết

**Launch Template**: blueprint cho EC2 — AMI, instance type, SG, user-data. ASG dùng template này mỗi khi cần tạo instance mới.

**Auto Scaling Group**: duy trì số instance trong khoảng min–max:
```
min=1 — desired=2 — max=4
```

CloudWatch Alarm kích hoạt:
- CPU > 70% → tăng `desired` → tạo instance mới (scale-out)
- CPU < 30% → giảm `desired` → xóa instance (scale-in)

---

## Thực hành

### 1.1 — Tạo Launch Template

```bash
LT_ID=$(aws ec2 create-launch-template \
  --launch-template-name "web-server-lt" \
  --version-description "v1" \
  --launch-template-data '{
    "ImageId": "ami-0c55b159cbfafe1f0",
    "InstanceType": "t3.micro",
    "SecurityGroupIds": ["'"$SG_ID"'"],
    "UserData": "'"$(echo '#!/bin/bash
apt-get update -y
apt-get install -y nginx
echo "healthy" > /var/www/html/health
systemctl enable nginx && systemctl start nginx' | base64 -w0)"'"
  }' \
  --query 'LaunchTemplate.LaunchTemplateId' --output text)

echo "export LT_ID=$LT_ID" >> /tmp/lab-env.sh
echo "Launch Template: $LT_ID"
```

### 1.2 — Tạo Auto Scaling Group

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --launch-template "LaunchTemplateName=web-server-lt,Version=\$Default" \
  --min-size 1 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "$SUBNET_1,$SUBNET_2" \
  --health-check-type EC2 --health-check-grace-period 30

echo "✅ ASG '$ASG_NAME': min=1, desired=2, max=4"

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].{Min:MinSize,Desired:DesiredCapacity,Max:MaxSize}' \
  --output table
```

### 1.3 — Tạo Scaling Policies

```bash
SCALE_OUT_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name "scale-out-policy" \
  --scaling-adjustment 1 \
  --adjustment-type ChangeInCapacity --cooldown 60 \
  --query 'PolicyARN' --output text)

SCALE_IN_ARN=$(aws autoscaling put-scaling-policy \
  --auto-scaling-group-name $ASG_NAME \
  --policy-name "scale-in-policy" \
  --scaling-adjustment -1 \
  --adjustment-type ChangeInCapacity --cooldown 120 \
  --query 'PolicyARN' --output text)

echo "export SCALE_OUT_ARN=$SCALE_OUT_ARN" >> /tmp/lab-env.sh
echo "export SCALE_IN_ARN=$SCALE_IN_ARN" >> /tmp/lab-env.sh
echo "✅ Scaling Policies sẵn sàng"
```

### 1.4 — Tạo CloudWatch Alarms

```bash
# Scale-out: CPU > 70% trong 2 phút
aws cloudwatch put-metric-alarm \
  --alarm-name "cpu-high-scale-out" \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 60 --evaluation-periods 2 \
  --threshold 70 --comparison-operator GreaterThanThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions $SCALE_OUT_ARN

# Scale-in: CPU < 30% trong 5 phút
aws cloudwatch put-metric-alarm \
  --alarm-name "cpu-low-scale-in" \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 60 --evaluation-periods 5 \
  --threshold 30 --comparison-operator LessThanThreshold \
  --dimensions "Name=AutoScalingGroupName,Value=$ASG_NAME" \
  --alarm-actions $SCALE_IN_ARN

echo "✅ CloudWatch Alarms: scale-out (CPU>70%) + scale-in (CPU<30%)"
```

---

## Câu hỏi

1. Tại sao ASG cần trải instances ra nhiều AZ?
2. **Cooldown period** là gì? Tại sao scale-in cần cooldown dài hơn scale-out?
3. Sự khác biệt giữa `ChangeInCapacity` và `ExactCapacity`?
