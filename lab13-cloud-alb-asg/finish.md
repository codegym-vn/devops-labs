#  Hoàn thành Lab 13: ALB + Auto Scaling Group

## Những gì bạn đã làm được

```
 Bước 1 — Launch Template + Auto Scaling Group
   Blueprint EC2 (AMI, type, user-data) → ASG (min=1, desired=2, max=4)
   CloudWatch Alarms: scale-out CPU>70%, scale-in CPU<30%

 Bước 2 — Application Load Balancer
   ALB + Target Group (Health Check /health) + Listener port 80
   Nginx proxy thật: least_conn + passive health check

 Bước 3 — Kiểm thử phân tải
   Round-robin thực tế: ~50% mỗi backend
   Mô phỏng backend lỗi: Health Check loại instance khỏi rotation
   Benchmark với wrk: đo throughput thực tế

 Bước 4 — Scale-out & Cleanup
   ASG tăng desired 2 → 3 → app-3 vào rotation
   Throughput tăng tương ứng khi thêm instance
   Dọn sạch: ALB, ASG, Launch Template, VPC, containers
```

---

## Bảng tra cứu nhanh

### Auto Scaling
```bash
# Tạo ASG
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name <NAME> \
  --launch-template "LaunchTemplateName=<LT>,Version=\$Default" \
  --min-size 1 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "<SUBNET1>,<SUBNET2>"

# Scale thủ công
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <NAME> --desired-capacity <N>

# Xem trạng thái instance trong ASG
aws autoscaling describe-auto-scaling-instances \
  --query 'AutoScalingInstances[*].{ID:InstanceId,State:LifecycleState,Health:HealthStatus}'
```

### Application Load Balancer
```bash
# Tạo ALB
aws elbv2 create-load-balancer --name <NAME> --type application \
  --subnets <SUBNET1> <SUBNET2> --security-groups <SG>

# Xem Target Health
aws elbv2 describe-target-health --target-group-arn <TG_ARN>

# Xem Access Logs (cần bật S3 logging)
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn <ALB_ARN> \
  --attributes Key=access_logs.s3.enabled,Value=true \
               Key=access_logs.s3.bucket,Value=<BUCKET>
```

### CloudWatch
```bash
# Xem Alarm state
aws cloudwatch describe-alarms --alarm-names <NAME> \
  --query 'MetricAlarms[0].{State:StateValue,Reason:StateReason}'

# Xem metrics của ASG
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<ASG> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Average
```

---

## Kết nối với các bài học tiếp theo

| Bước tiếp | Mô tả |
|-----------|-------|
| **Lab 14: FinOps** | Phân tích chi phí của ALB, ASG, EC2 — tối ưu để tiết kiệm |
| **Terraform Topic 2** | Viết toàn bộ hạ tầng này bằng code: `aws_lb`, `aws_autoscaling_group`, `aws_launch_template` |

---

## Tự kiểm tra

- [ ] Giải thích được sự khác biệt giữa ALB (Layer 7) và NLB (Layer 4)
- [ ] Vẽ được luồng traffic từ client → ALB → Target Group → EC2
- [ ] Hiểu tại sao Health Check là bắt buộc trong kiến trúc HA
- [ ] Biết cấu hình CloudWatch Alarm kích hoạt Scaling Policy
- [ ] Tự scale-out/in ASG không nhìn tài liệu
