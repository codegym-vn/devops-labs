# Lab: FinOps — Budget Alerts, Cost Allocation Tags và Phân tích Tài nguyên Idle

## Bối cảnh

Sau 2 tháng đưa hệ thống lên Cloud, team nhận được hóa đơn tháng này cao gấp đôi dự tính. CEO yêu cầu **báo cáo phân tích chi phí và đề xuất tối ưu 30%** trong vòng 1 tuần. Bạn là kỹ sư FinOps phụ trách xử lý.

## Ba trụ cột của FinOps

```
        INFORM              OPTIMIZE            OPERATE
    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │ Cost Visibility│    │ Cost Reduction│    │ Cost Control│
    │             │     │             │     │             │
    │ • Tagging   │────►│ • Right-size│────►│ • Budgets   │
    │ • CUR Report│     │ • Schedule  │     │ • Alerts    │
    │ • Dashboard │     │ • Reserved  │     │ • Governance│
    └─────────────┘     └─────────────┘     └─────────────┘
```

## Mục tiêu học tập

- ✅ Gắn **Cost Allocation Tags** lên toàn bộ tài nguyên theo chuẩn
- ✅ Thiết lập **AWS Budgets** với cảnh báo email tự động
- ✅ Phân tích **Cost & Usage Report** theo service và theo tag
- ✅ Dùng script phát hiện **tài nguyên idle** và đề xuất right-sizing
- ✅ Lập **báo cáo tối ưu chi phí** cụ thể với con số tiết kiệm

## Tài nguyên có sẵn trong lab

```bash
source /tmp/lab-env.sh
echo "5 EC2 instances: $INSTANCE_IDS"
ls /opt/lab-data/
```
