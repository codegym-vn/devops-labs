# Lab 13: Cân Bằng Tải Ứng Dụng (ALB) & Tự Động Mở Rộng (Auto Scaling)

Chào mừng bạn đến với bài thực hành nâng cao về tính sẵn sàng cao (**High Availability - HA**) và khả năng co giãn linh hoạt (**Elasticity**) trên Cloud bằng **AWS CLI** và **LocalStack**.

---

## 1. Kiến Trúc Cân Bằng Tải & Co Giãn Tự Động (ALB + ASG)

Trong thực tế sản xuất, một máy chủ đơn lẻ (Single Instance) luôn tiềm ẩn nguy cơ sập toàn bộ hệ thống (Single Point of Failure - SPOF). Để đạt chuẩn sẵn sàng cao, các kỹ sư DevOps kết hợp **Application Load Balancer (ALB)** và **Auto Scaling Group (ASG)**:

```
                            Internet (Người dùng)
                                     │
                                     ▼ (Port 80 HTTP)
           ┌───────────────────────────────────────────────────┐
           │      Application Load Balancer (web-alb)          │
           │      (Phân bổ tải đa vùng us-east-1a / 1b)        │
           └─────────────────────────┬─────────────────────────┘
                                     │
                                     ▼ (Chuyển tiếp qua Listener)
           ┌───────────────────────────────────────────────────┐
           │            Target Group (web-tg)                  │
           │            (Health Check: /health)                │
           └─────────────────────────┬─────────────────────────┘
                                     │
                                     ▼ (Tự động đăng ký mục tiêu)
    ┌─────────────────────────────────────────────────────────────────┐
    │                 Auto Scaling Group (web-asg)                    │
    │                 • Min: 1  |  Desired: 2  |  Max: 4              │
    │                 • Sử dụng: Launch Template (web-template)       │
    │                                                                 │
    │    ┌──────────────────────────┐    ┌──────────────────────────┐ │
    │    │ EC2 Instance 1 (1a)      │    │ EC2 Instance 2 (1b)      │ │
    │    │ [ Nginx Web App ]        │    │ [ Nginx Web App ]        │ │
    │    └──────────────────────────┘    └──────────────────────────┘ │
    └─────────────────────────────────────────────────────────────────┘
```

---

## 2. Các Thành Phần Cốt Lõi Cần Làm Chủ

1. **Launch Template (`aws ec2 create-launch-template`):**  
   Bản thiết kế khuôn mẫu quy định: AMI nào, cấu hình instance nào (`t2.micro`), Security Group nào, và User Data script nào để khởi động app khi máy vừa bật.
2. **Auto Scaling Group (`aws autoscaling create-auto-scaling-group`):**  
   Bộ điều phối tự động duy trì số lượng máy ảo mong muốn (`desired-capacity`). Khi tải tăng, ASG tự động sinh thêm máy ảo (Scale-out); khi tải giảm, ASG tự động tắt bớt để tiết kiệm chi phí (Scale-in).
3. **Application Load Balancer (`aws elbv2 create-load-balancer`):**  
   Bộ cân bằng tải Layer 7 (HTTP/HTTPS), tiếp nhận kết nối của người dùng và điều hướng thông minh theo thuật toán Round-Robin hoặc Least Outstanding Requests.
4. **Target Group & Health Check (`aws elbv2 create-target-group`):**  
   Tập hợp các instance nhận lưu lượng. ALB liên tục gửi tín hiệu kiểm tra sức khỏe (**Health Check**). Nếu một máy ảo bị treo hoặc sập, ALB sẽ **ngừng chuyển tiếp lưu lượng** đến máy đó và thông báo cho ASG thay thế bằng máy ảo mới.

## 3. Mục Tiêu Học Tập (Chuẩn Thang Đo Bloom)

Sau khi hoàn thành bài thực hành, bạn sẽ đạt được các năng lực sau:

* **[Hiểu - Understand]**: Giải thích được cơ chế kiểm tra sức khỏe (Health Check), vòng đời tự phục hồi (Self-Healing) khi instance bị lỗi và nguyên lý hoạt động của kiến trúc High Availability (HA) đa vùng.
* **[Vận dụng - Apply]**: Sử dụng thành thạo **AWS CLI** để tạo Launch Template, kích hoạt Auto Scaling Group đa vùng (Multi-AZ), cấu hình Application Load Balancer và thiết lập Listener chuyển tiếp lưu lượng.
* **[Phân tích - Analyze]**: Phân tích và kiểm chứng thuật toán cân bằng tải `round_robin` của Target Group, so sánh hiệu quả giữa mở rộng theo chiều dọc (Vertical Scaling) và mở rộng theo chiều ngang (Horizontal Scaling).
* **[Tạo lập & Đánh giá - Create & Evaluate]**: Xây dựng hoàn chỉnh một hệ thống co giãn tự động không có điểm chết duy nhất (Zero SPOF), kích hoạt sự kiện Scale-out khi tải tăng và thực thi quy trình dọn dẹp tài nguyên an toàn với `--force-delete`.

---

## 4. Lộ Trình Thực Hành

* **Bước 1:** Tạo Security Groups, Launch Template và kích hoạt Auto Scaling Group (`desired=2`).
* **Bước 2:** Tạo Target Group, Application Load Balancer, Listener và liên kết với ASG.
* **Bước 3:** Kiểm tra trạng thái Target Health và quan sát cơ chế phân tải Round-Robin.
* **Bước 4:** Giả lập sự kiện mở rộng quy mô (Scale-out lên 4 máy ảo) và thực hành quy trình dọn dẹp tài nguyên.
