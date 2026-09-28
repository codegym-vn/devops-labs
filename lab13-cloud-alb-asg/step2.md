# Bước 2: Tạo Application Load Balancer & Target Group

Trong bước này, bạn sẽ sử dụng **AWS CLI** để tạo một bộ cân bằng tải ứng dụng (**Application Load Balancer - ALB**), thiết lập nhóm mục tiêu (**Target Group**) kèm cơ chế kiểm tra sức khỏe (**Health Check**), và kết nối trực tiếp với Auto Scaling Group.

---

## 1. Lý Thuyết: Cơ Chế Hoạt Động Của ALB & Target Group

1. **Target Group (TG):** Nhóm các máy chủ nhận lưu lượng. Bạn khai báo cổng (`80`), giao thức (`HTTP`), và đường dẫn kiểm tra sức khỏe (ví dụ `/health`). ALB sẽ định kỳ gửi request tới đường dẫn này; nếu server trả về HTTP 200, server được đánh dấu là `healthy`.
2. **Application Load Balancer (ALB):** Tiếp nhận lưu lượng Internet tại mặt tiền, phân phối đều sang các máy chủ trong Target Group. ALB yêu cầu tối thiểu **2 Subnets thuộc 2 Availability Zones khác nhau** để đảm bảo khả năng chịu lỗi khi 1 trung tâm dữ liệu gặp sự cố.
3. **Listener:** Quy tắc lắng nghe lưu lượng trên ALB (ví dụ: đón ở cổng 80 và chuyển tiếp `forward` sang Target Group).
4. **Cơ chế tự động đăng ký (Auto-Registration):** Khi bạn gắn Target Group vào ASG, bất cứ khi nào ASG tạo thêm máy ảo mới, máy ảo đó sẽ **tự động đăng ký IP** vào Target Group mà không cần can thiệp thủ công!

---

## 2. Thực Hành

Tải lại các biến môi trường:

```bash
source /tmp/lab-env.sh
```{{exec}}

---

### 2.1 — Khởi Tạo Target Group (`web-tg`)

Tạo nhóm mục tiêu HTTP cổng 80 gắn với VPC và thiết lập đường dẫn kiểm tra sức khỏe `/health`:

```bash
TG_ARN=$(aws elbv2 create-target-group \
  --name "web-tg" \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPC_ID \
  --health-check-protocol HTTP \
  --health-check-path "/health" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "✅ Đã tạo Target Group thành công!"
echo "TG_ARN=$TG_ARN" >> /tmp/lab-env.sh
```{{exec}}

---

### 2.2 — Khởi Tạo Application Load Balancer (`web-alb`)

Tạo Load Balancer công khai (`internet-facing`), gắn vào 2 Subnets đa vùng (`$SUBNET_1,$SUBNET_2`) và bảo vệ bằng nhóm bảo mật `$ALB_SG_ID`:

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name "web-alb" \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "✅ Đã tạo Application Load Balancer thành công!"
echo "ALB_ARN=$ALB_ARN" >> /tmp/lab-env.sh
```{{exec}}

---

### 2.3 — Tạo Listener Chuyển Tiếp Lưu Lượng Port 80

Cấu hình Listener đón lưu lượng HTTP trên cổng 80 của ALB và chuyển tiếp (forward) vào Target Group:

```bash
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "✅ Đã tạo Listener thành công: $LISTENER_ARN"
echo "LISTENER_ARN=$LISTENER_ARN" >> /tmp/lab-env.sh
```{{exec}}

---

### 2.4 — Gắn Target Group Vào Auto Scaling Group

Đây là bước kết nối mấu chốt: Ra lệnh cho ASG tự động đăng ký mọi máy ảo nó quản lý vào Target Group:

```bash
aws autoscaling attach-load-balancer-target-groups \
  --auto-scaling-group-name "web-asg" \
  --target-group-arns $TG_ARN

echo "✅ Đã liên kết thành công: Auto Scaling Group ➔ Target Group ➔ ALB!"
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP]
> Mỗi Load Balancer trên Cloud luôn được cấp phát một tên miền DNS công khai duy nhất (DNS Name).

**Yêu cầu:** Hãy dùng lệnh `aws elbv2 describe-load-balancers` để tìm tên miền `DNSName` của bộ cân bằng tải `web-alb`:

```bash
aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].[LoadBalancerName, DNSName, State.Code]' \
  --output table
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
