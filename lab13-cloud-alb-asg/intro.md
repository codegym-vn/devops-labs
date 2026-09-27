# Lab: Thực hành triển khai Application Load Balancer và thiết lập Auto Scaling Group

## Bối cảnh

Web server đơn từ Lab 12 không đủ để đáp ứng traffic cao điểm. Bạn được yêu cầu nâng cấp kiến trúc lên **High Availability** — nhiều instance chạy song song phía sau một Load Balancer, tự động scale khi tải tăng.

## Kiến trúc cần xây dựng

```
           Internet
               │
      ┌────────▼────────┐
      │  Application    │
      │  Load Balancer  │  ← Phân phối traffic theo thuật toán
      └────────┬────────┘
               │
     ┌─────────┼─────────┐
     ▼         ▼         ▼
 [app-1]    [app-2]   [app-3]   ← EC2 Instances trong Auto Scaling Group
 port 8081  port 8082  port 8083
 AZ-1a      AZ-1b      AZ-1a   ← Trải đều trên nhiều Availability Zone

     ↕ CloudWatch Alarm
     Scale-out khi CPU > 70%
     Scale-in  khi CPU < 30%
```

## Mục tiêu học tập

- ✅ Tạo **Launch Template** định nghĩa blueprint cho EC2 instance
- ✅ Thiết lập **Auto Scaling Group** với chính sách min/max/desired
- ✅ Cấu hình **Application Load Balancer** và **Target Group** với Health Check
- ✅ Quan sát cơ chế **round-robin** phân phối request
- ✅ Giả lập **scale-out**: thêm instance khi tải tăng
- ✅ Cấu hình **CloudWatch Alarm** kích hoạt scaling policy

## Công cụ

| Công cụ | Vai trò |
|---------|---------|
| **AWS CLI + LocalStack** | Tạo Launch Template, ASG, ALB, Target Group, CloudWatch |
| **Docker** | Chạy backend containers đóng vai EC2 instances thật |
| **Nginx (host)** | Đóng vai ALB — thực sự proxy và phân tải HTTP |
| **wrk** | Benchmark HTTP để đo throughput và kiểm thử |

> 💡 VPC, Subnet và Security Group đã được tạo sẵn bởi `background.sh`.
> Chạy `source /tmp/lab-env.sh` để nạp biến môi trường.
