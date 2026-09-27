# Lab 13: Application Load Balancer · Auto Scaling Group

## Bối cảnh

Web server đơn từ Lab 12 không đáp ứng được traffic cao điểm. Nhiệm vụ: nâng cấp lên **High Availability** — nhiều instance chạy song song phía sau một Load Balancer, tự động scale khi tải tăng.

## Kiến trúc

```
        Internet
            │
     ┌──────▼──────┐
     │     ALB     │  ← Phân tải theo thuật toán
     └──────┬──────┘
            │
  ┌─────────┼─────────┐
  ▼         ▼         ▼
[app-1]  [app-2]  [app-3]   ← EC2 trong Auto Scaling Group
 AZ-1a    AZ-1b    AZ-1a    ← Trải đều trên nhiều AZ

CloudWatch: scale-out CPU > 70% / scale-in CPU < 30%
```

## Mục tiêu

- Tạo Launch Template và Auto Scaling Group (min/max/desired)
- Cấu hình ALB + Target Group với Health Check
- Quan sát phân phối round-robin
- Giả lập scale-out và đo throughput trước/sau

## Công cụ

| Công cụ | Vai trò |
|---------|---------|
| AWS CLI + LocalStack | Tạo ASG, ALB, CloudWatch |
| Docker | Chạy backend containers (đóng vai EC2) |
| Nginx | Proxy + phân tải HTTP thật |
| wrk | Benchmark throughput |
