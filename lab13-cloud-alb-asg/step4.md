# Bước 4: Giả Lập Mở Rộng Quy Mô (Scale-Out) & Dọn Dẹp Tài Nguyên

Trong bước cuối cùng, bạn sẽ sử dụng **AWS CLI** để kích hoạt sự kiện **Scale-out** (mở rộng quy mô từ 2 lên 4 máy ảo khi tải tăng), sau đó thực hành quy trình **Dọn dẹp tài nguyên (FinOps Cleanup)** theo chuẩn DevOps.

---

## 1. Lý Thuyết: Cơ Chế Co Giãn Tự Động (Auto Scaling Dynamics)

* **Scale-Out (Mở rộng theo chiều ngang):** Khi có đợt Flash Sale hoặc tải CPU toàn cụm vượt ngưỡng (ví dụ > 70%), CloudWatch Alarms sẽ kích hoạt Scaling Policy ra lệnh cho ASG tăng `desired-capacity` từ 2 lên 4.
* **Thời gian hạ nhiệt (Cooldown Period):** Sau khi sinh máy ảo mới, ASG sẽ tạm dừng việc scale trong một khoảng thời gian (mặc định 300 giây) để chờ máy ảo nạp xong ứng dụng và tải ổn định, tránh tình trạng "giật cục" (Flapping).
* **Scale-In (Thu hẹp quy mô):** Khi đêm xuống, lưu lượng giảm, ASG tự động tắt bớt các máy ảo dư thừa để đưa chi phí về mức tối thiểu.

```
       [ Bình thường ]                             [ Tải tăng cao ]
     Desired Capacity: 2                         Desired Capacity: 4
┌──────────────┬──────────────┐         ┌──────────────┬──────────────┬──────────────┬──────────────┐
│  Instance 1  │  Instance 2  │  ───►   │  Instance 1  │  Instance 2  │  Instance 3  │  Instance 4  │
└──────────────┴──────────────┘         └──────────────┴──────────────┴──────────────┴──────────────┘
```

---

## 2. Thực Hành

Tải lại các biến môi trường:

```bash
source /tmp/lab-env.sh
```{{exec}}

---

### 4.1 — Giả Lập Sự Kiện Scale-Out Lên 4 Máy Ảo

Kích hoạt lệnh nâng năng lực phục vụ mong muốn (`desired-capacity`) từ 2 lên 4:

```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "web-asg" \
  --desired-capacity 4

echo "✅ Đã gửi lệnh Scale-out: Đặt Desired Capacity = 4!"
```{{exec}}

Kiểm tra sự thay đổi trong Auto Scaling Group:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query 'AutoScalingGroups[0].[AutoScalingGroupName, DesiredCapacity, MinSize, MaxSize, length(Instances)]' \
  --output table
```{{exec}}

Liệt kê danh sách chi tiết 4 máy ảo đang được quản lý:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "web-asg" \
  --query 'AutoScalingGroups[0].Instances[].[InstanceId, LifecycleState, HealthStatus]' \
  --output table
```{{exec}}

---

## 3. Bài Tập Thử Thách: Dọn Dẹp Tài Nguyên Cụm Cân Bằng Tải

> [!WARNING]
> Cụm ALB và Auto Scaling Group tiêu tốn chi phí rất lớn nếu bị bỏ quên trên Cloud thật. Kỹ năng dọn dẹp sạch sẽ tài nguyên là bắt buộc!

**Yêu cầu:** Thực hiện xóa cụm tài nguyên theo đúng quy trình:
1. **Xóa Auto Scaling Group:** Dùng cờ `--force-delete` để ASG tự động terminate toàn bộ các máy ảo con.
2. **Xóa Application Load Balancer:** Giải phóng tài nguyên ALB.

Chạy các lệnh dọn dẹp sau:

```bash
# 1. Hủy Auto Scaling Group (sẽ tự động terminate toàn bộ instances)
echo "Đang xóa Auto Scaling Group web-asg..."
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name "web-asg" \
  --force-delete

# 2. Xóa Application Load Balancer
echo "Đang xóa Application Load Balancer..."
aws elbv2 delete-load-balancer \
  --load-balancer-arn $ALB_ARN

# 3. Xóa Target Group
echo "Đang xóa Target Group..."
aws elbv2 delete-target-group \
  --target-group-arn $TG_ARN

echo "✅ Đã dọn dẹp sạch sẽ toàn bộ cụm ALB và Auto Scaling Group!"
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và xác nhận hoàn thành bài lab!
