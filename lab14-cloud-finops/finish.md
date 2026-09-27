# 🎉 Hoàn thành Lab 14: FinOps — Budget Alerts, Tags & Cost Optimization

## Những gì bạn đã làm được

```
✅ Bước 1 — Cost Allocation Tags
   5 EC2 instances + VPC + Subnet được gắn đủ 4 tags chuẩn
   Tag compliance check: 0 resources thiếu tag

✅ Bước 2 — AWS Budgets
   1 budget tổng ($100/tháng) + 3 budget theo project
   Alert 80% và 100% với email notification

✅ Bước 3 — Cost & Usage Report Analysis
   Breakdown theo Service, Project, Environment, Owner
   Phát hiện ngày chi phí đột biến

✅ Bước 4 — Idle Resource Analysis + Báo cáo
   Phát hiện 3/5 instances cần tối ưu
   Báo cáo đề xuất tiết kiệm ~47% chi phí/tháng
```

## Bảng tra cứu nhanh

### Tags
```bash
aws ec2 create-tags --resources <ID> \
  --tags Key=Project,Value=<P> Key=Environment,Value=<E> Key=Owner,Value=<O>

# Tìm untagged resources
aws ec2 describe-instances \
  --query "Reservations[*].Instances[?!Tags[?Key=='Project']].InstanceId" --output text
```

### Budgets
```bash
aws budgets create-budget --account-id <ACCOUNT> --budget '{...}'
aws budgets describe-budgets --account-id <ACCOUNT>
aws budgets delete-budget --account-id <ACCOUNT> --budget-name <NAME>
```

## Kết nối với Terraform (Topic 2-3)

```hcl
# Terraform tự động gắn tags cho mọi resource
resource "aws_instance" "web" {
  ami           = "ami-xxx"
  instance_type = "t3.micro"
  tags = {
    Project     = "e-commerce"
    Environment = "production"
    Owner       = "team-backend"
    ManagedBy   = "terraform"
  }
}
```

## Tự kiểm tra

- [ ] Giải thích được 3 giai đoạn FinOps: Inform → Optimize → Operate
- [ ] Biết gắn Tags đúng chuẩn và kiểm tra compliance
- [ ] Cấu hình Budget với nhiều mức alert khác nhau
- [ ] Đọc và phân tích Cost & Usage Report
- [ ] Đề xuất right-sizing dựa trên utilization metrics
