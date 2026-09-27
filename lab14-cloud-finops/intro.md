# Lab 14: FinOps — Tags · Budgets · Cost Optimization

## Bối cảnh

Hóa đơn Cloud tháng này cao gấp đôi dự tính. CEO yêu cầu báo cáo phân tích và đề xuất tối ưu 30% trong 1 tuần.

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
