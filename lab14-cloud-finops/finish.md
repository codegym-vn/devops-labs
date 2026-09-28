# 🏆 Chúc mừng! Bạn đã hoàn thành Lab: Cloud FinOps — Quản Trị & Tối Ưu Chi Phí Đám Mây

Bạn vừa hoàn thành một trong những kỹ năng giá trị nhất của kỹ sư Cloud / DevOps hiện đại: **FinOps (Financial Operations)** — biến chi phí đám mây từ một "hộp đen" khó lường thành một hệ thống minh bạch, có kiểm soát và được tối ưu liên tục!

---

## 1. Tóm Tắt 3 Giai Đoạn Vòng Lặp FinOps Bạn Vừa Thực Hành

```text
 1. INFORM (Minh bạch hóa & Phân bổ chi phí):
    • Gắn bộ 4 nhãn chuẩn Cost Allocation Tags (Project, Environment, Owner, CostCenter) bằng AWS CLI.
    • Phân tích báo cáo chi tiết Cost & Usage Report (CUR) theo từng phòng ban và dịch vụ.

 2. OPTIMIZE (Tối ưu hóa tài nguyên):
    • Thiết lập hệ thống cảnh báo sớm AWS Budgets đa tầng (ngưỡng 80% ACTUAL, 110% FORECAST).
    • Quét dữ liệu sử dụng CPU để phát hiện 3 máy ảo chạy ngầm lãng phí (Idle Resources).

 3. OPERATE (Thực thi hành động liên tục):
    • Lập báo cáo FinOps Report tổng thể đề xuất cắt giảm ~53% chi phí compute.
    • Thực thi lệnh AWS CLI terminate-instances để dứt điểm loại bỏ máy chủ rác.
```

---

## 2. Bảng Tra Cứu Lệnh AWS CLI FinOps (Cheat Sheet)

### 2.1 — Quản lý Cost Allocation Tags
```bash
# Gắn Tags cho một hoặc nhiều tài nguyên
aws ec2 create-tags --resources <INSTANCE_ID> \
  --tags Key=Project,Value=e-commerce Key=Environment,Value=production \
         Key=Owner,Value=team-backend Key=CostCenter,Value=CC-001

# Lọc máy chủ theo Tag
aws ec2 describe-instances --filters "Name=tag:Project,Values=e-commerce"

# Tìm các máy chủ chưa được gắn tag Project (Untagged Resources)
aws ec2 describe-instances \
  --query "Reservations[*].Instances[?!Tags[?Key=='Project']].InstanceId" --output text
```

### 2.2 — Quản lý Ngân sách AWS Budgets
```bash
# Tạo Budget bằng file cấu hình JSON
aws budgets create-budget \
  --account-id <ACCOUNT_ID> \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json

# Liệt kê danh sách các Budget hiện có
aws budgets describe-budgets --account-id <ACCOUNT_ID>
```

### 2.3 — Thực thi tối ưu tài nguyên (Optimization Execution)
```bash
# Hủy máy ảo idle không dùng
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>

# Tạm dừng máy ảo ngoài giờ hành chính
aws ec2 stop-instances --instance-ids <INSTANCE_ID>

# Thay đổi cấu hình máy ảo (Right-sizing sau khi stop)
aws ec2 modify-instance-attribute --instance-id <INSTANCE_ID> --instance-type '{"Value": "t3.small"}'
```

---

## 3. Câu Hỏi Phỏng Vấn Tuyển Dụng FinOps / DevOps

1. **Sự khác nhau giữa Reserved Instances (RI) và AWS Savings Plans là gì?**
   * *Trả lời:* Cả hai đều yêu cầu cam kết thời gian 1 hoặc 3 năm để nhận mức giảm giá 30% - 72%. Tuy nhiên, **Reserved Instances (Standard)** gắn chặt với một Instance Type và Availability Zone cụ thể; trong khi **Compute Savings Plans** linh hoạt hơn nhiều: bạn chỉ cần cam kết mức chi tiêu tính theo $/giờ (ví dụ $10/hour), áp dụng tự động cho bất kỳ instance family nào (t3, c5, m5), bất kỳ region nào, và thậm chí cả AWS Fargate / Lambda.
2. **Làm thế nào để ép buộc các lập trình viên / kỹ sư DevOps luôn phải gắn tag khi tạo tài nguyên mới trên Cloud?**
   * *Trả lời:* Sử dụng chính sách **AWS SCP (Service Control Policies)** trong AWS Organizations hoặc **AWS Tag Policies** để từ chối (`Deny`) quyền `ec2:RunInstances` nếu trong request tạo máy ảo thiếu các tag bắt buộc (như `Project`, `Environment`, `Owner`). Kết hợp kiểm tra tự động bằng AWS Config Rule (`required-tags`).
