# Lab 13: High Availability — Load Balancer & Auto Scaling

## Vấn đề cần giải quyết

Web server đơn từ Lab 12 có **single point of failure**: server down → toàn bộ service sập. Giải pháp:

```
Trước (Lab 12)           Sau (Lab 13)
                         
  [Client]                   [Client]
      │                          │
  [Server]            ┌──────────▼──────────┐
  ← down → ❌         │   Load Balancer      │
                      └──────────┬──────────┘
                         ┌───────┼───────┐
                         ▼       ▼       ▼
                      [app-1] [app-2] [app-3]
                      ← 1 down → 2 còn lại → ✅
```

## Khái niệm

**Load Balancer**: phân phối traffic đến nhiều server — không có single point of failure.

**Auto Scaling**: tự động thêm/bớt server dựa trên tải:
- Tải tăng → scale-out (thêm instance)
- Tải giảm → scale-in (bớt instance)
- Giữ min/max để kiểm soát chi phí

**Health Check**: Load Balancer định kỳ kiểm tra sức khỏe backend — instance fail → tự động loại khỏi rotation.

## Tương đương trên Cloud

| Khái niệm | Lab (Docker + Nginx) | AWS | GCP | Azure |
|-----------|---------------------|-----|-----|-------|
| Load Balancer | Nginx upstream | ALB | Cloud Load Balancing | Azure Load Balancer |
| Instance template | Docker image + config | Launch Template | Instance Template | VM Scale Set |
| Auto Scaling | `docker compose scale` / script | Auto Scaling Group | Managed Instance Group | VMSS |
| Health Check | Nginx passive / script | ALB Health Check | Health Check | Load Balancer Probe |
| Scale trigger | Bash script monitoring | CloudWatch Alarm | Cloud Monitoring | Azure Monitor |

## Mục tiêu

- Cấu hình Nginx làm Load Balancer với thuật toán least_conn
- Khởi động nhiều backend containers (Compute Instances)
- Quan sát phân phối traffic và Health Check
- Mô phỏng scale-out: tăng số instance khi tải cao
- Đo throughput trước/sau scale-out bằng `wrk`
