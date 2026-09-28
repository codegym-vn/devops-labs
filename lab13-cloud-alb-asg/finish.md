# 🏆 Chúc mừng! Bạn đã hoàn thành Lab: Triển Khai ALB & Auto Scaling Group

Bạn vừa làm chủ một trong những kiến trúc kinh điển và quan trọng nhất của kỹ sư Cloud / DevOps: **Xây dựng hệ thống tự phục hồi (Self-Healing) và co giãn không giới hạn (Auto-Scaling)** trên AWS!

---

## 1. Tóm Tắt Kiến Trúc Bạn Vừa Xây Dựng

```text
 1. Launch Template (web-launch-template):
    Khuôn mẫu máy chủ tiêu chuẩn với cấu hình t2.micro, Base64 User Data và Security Group app-sg.

 2. Auto Scaling Group (web-asg):
    Tự động phân bổ máy chủ vào 2 Availability Zones (us-east-1a và us-east-1b), duy trì desired-capacity và tự động đăng ký vào Target Group.

 3. Application Load Balancer (web-alb):
    Đón nhận lưu lượng người dùng Internet trên cổng 80, liên tục Health Check đường dẫn /health, phân phối tải thông minh bằng thuật toán Round-Robin.

 4. Quản trị Co giãn & Dọn dẹp (FinOps):
    Thực hành Scale-out lên 4 máy chủ khi có tải lớn, và thực hiện xóa dọn tài nguyên an toàn với cờ --force-delete.
```

---

## 2. Bảng Tra Cứu Lệnh AWS CLI (Cheat Sheet)

### 2.1 — Quản lý Launch Template & Auto Scaling
```bash
# Tạo Launch Template
aws ec2 create-launch-template --launch-template-name <NAME> --launch-template-data file://<JSON_FILE>

# Tạo Auto Scaling Group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name <NAME> \
  --launch-template "LaunchTemplateName=<NAME>,Version=\$Latest" \
  --min-size 1 --max-size 4 --desired-capacity 2 --vpc-zone-identifier "<SUBNET_1>,<SUBNET_2>"

# Điều chỉnh quy mô (Scale-out / Scale-in)
aws autoscaling set-desired-capacity --auto-scaling-group-name <NAME> --desired-capacity <NUM>

# Xóa Auto Scaling Group bắt buộc
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name <NAME> --force-delete
```

### 2.2 — Quản lý Application Load Balancer
```bash
# Tạo Target Group
aws elbv2 create-target-group --name <NAME> --protocol HTTP --port 80 --vpc-id <VPC> --health-check-path /health

# Tạo Application Load Balancer đa vùng
aws elbv2 create-load-balancer --name <NAME> --subnets <SUB_1> <SUB_2> --security-groups <SG>

# Tạo Listener chuyển tiếp cổng 80 vào Target Group
aws elbv2 create-listener --load-balancer-arn <ALB_ARN> --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=<TG_ARN>

# Gắn Target Group vào Auto Scaling Group
aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name <ASG> --target-group-arns <TG_ARN>

# Giám sát sức khỏe mục tiêu
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

---

## 3. Câu Hỏi Phỏng Vấn Tuyển Dụng Thường Gặp

1. **Khi nào nên chọn Application Load Balancer (ALB) và khi nào nên chọn Network Load Balancer (NLB)?**
   * *Trả lời:* Dùng **ALB** khi cần cân bằng tải tầng ứng dụng Layer 7 (HTTP/HTTPS, gRPC, WebSocket), cần định tuyến dựa trên URL path (`/api` vs `/static`), host header hoặc cần SSL Termination. Dùng **NLB** khi cần hiệu năng siêu cao (hàng triệu request/giây, độ trễ micro-second), giao thức tầng 4 TCP/UDP thuần túy, hoặc yêu cầu IP tĩnh (Static IP / Elastic IP) cố định cho Load Balancer.
2. **"Sticky Sessions" (Session Affinity) là gì và có nên bật nó không?**
   * *Trả lời:* Sticky Session giúp định tuyến tất cả các request từ một người dùng cụ thể về đúng một máy chủ backend duy nhất bằng Cookie. Chỉ nên bật khi ứng dụng lưu trữ phiên làm việc (Session state) cục bộ trong bộ nhớ RAM của server; khuyến nghị chuẩn Cloud là đưa session sang Redis/Memcached (Stateless architecture) để không cần bật Sticky Session, giúp tải được phân phối đều hơn.
