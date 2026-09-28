# Lab 14: FinOps — Quản lý và Tối ưu Chi phí Cloud

## FinOps là gì?

**FinOps** (Financial Operations) là văn hóa và quy trình giúp team engineering kiểm soát chi phí Cloud, đưa ra quyết định tài chính có căn cứ.

Không phải AWS-specific hay GCP-specific — đây là tư duy áp dụng cho **mọi Cloud provider**.

```
  INFORM              OPTIMIZE            OPERATE
  ─────────────       ─────────────       ─────────────
  Visibility:         Giảm lãng phí:      Kiểm soát:
  • Tagging           • Right-sizing      • Budget alerts
  • Cost reports      • Schedule stop     • Governance
  • Dashboards        • Reserved/Commit   • Chargeback
```

## Vấn đề thực tế

Team engineer thường bỏ qua chi phí Cloud vì:
1. **Không nhìn thấy**: bill đến cuối tháng mới biết
2. **Không biết ai dùng gì**: thiếu tagging → không trace được
3. **Tài nguyên "zombie"**: server test không ai dùng vẫn chạy tháng này qua tháng khác

## Ba công cụ quan trọng

| Công cụ | Mục đích |
|---------|---------|
| **Tags/Labels** | Phân bổ chi phí theo project, team, môi trường |
| **Budget Alerts** | Cảnh báo trước khi vượt ngân sách |
| **Cost Reports** | Phân tích chi tiết — service nào tốn nhiều nhất |

## Dataset có sẵn

Lab này dùng **dataset mô phỏng** (không phụ thuộc Cloud provider nào):

```bash
ls /opt/lab-data/
# cost-usage-report.csv     ← 30 ngày chi phí, ~400 dòng
# resource-utilization.json ← CPU/RAM metrics 5 servers
# analyze-cost.py           ← script phân tích chi phí
# find-idle-resources.py    ← script phát hiện server idle
```

## Mục Tiêu

- Nắm vững 3 giai đoạn của văn hóa FinOps (Inform, Optimize, Operate)
- Quản trị Cost Allocation Tags và cấu hình cảnh báo AWS Budgets
- Phân tích báo cáo chi phí Cost & Usage Report (CUR)
- Phát hiện tài nguyên lãng phí và thực thi tối ưu chi phí bằng AWS CLI
