# Lab 14: FinOps — Tags · Budgets · Cost Optimization

## Bối cảnh

Hóa đơn Cloud tháng này cao gấp đôi dự tính. CEO yêu cầu báo cáo phân tích và đề xuất tối ưu 30% trong 1 tuần.

---

## Nhắc lại: LocalStack & AWS CLI

```bash
# Nếu LocalStack chưa chạy:
docker run -d --rm --name localstack \
  -p 4566:4566 \
  -e SERVICES=ec2,elbv2,autoscaling,cloudwatch,budgets \
  localstack/localstack:3.8

alias aws='aws --endpoint-url=http://localhost:4566'
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

> Lab này **không dùng AWS Billing thật** (vì LocalStack không có billing API). Thay vào đó, dataset chi phí 30 ngày đã được tạo sẵn trong `/opt/lab-data/` bởi background script.

---

## Ba trụ cột FinOps

```
  INFORM          OPTIMIZE        OPERATE
  • Tagging   →   • Right-size → • Budgets
  • CUR Report    • Schedule      • Alerts
  • Dashboard     • Reserved      • Governance
```

## Mục tiêu

- Gắn Cost Allocation Tags đúng chuẩn lên mọi tài nguyên
- Thiết lập AWS Budgets với alert 80% và 100%
- Phân tích Cost & Usage Report theo service và tag
- Phát hiện tài nguyên idle và lập báo cáo right-sizing

## Dataset có sẵn

```bash
ls /opt/lab-data/
# cost-usage-report.csv     ← 30 ngày chi phí, ~400 dòng
# resource-utilization.json ← utilization metrics 5 instances
# analyze-cost.py           ← script phân tích CUR
# find-idle-resources.py    ← script phát hiện idle
```
