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

## Mục Tiêu Học Tập

Sau khi hoàn thành bài thực hành, bạn sẽ đạt được các năng lực sau:

* **Làm chủ văn hóa FinOps:** Nắm vững 3 giai đoạn của vòng đời FinOps (*Inform ➔ Optimize ➔ Operate*), phân biệt cơ chế cảnh báo theo thực chi (`ACTUAL`) và theo dự báo (`FORECASTED`) của AWS Budgets.
* **Quản trị nhãn & Ngân sách:** Sử dụng AWS CLI để gắn bộ nhãn chuẩn Cost Allocation Tags lên các máy ảo EC2 và thiết lập cấu hình ngân sách AWS Budgets JSON đa tầng.
* **Phân tích báo cáo chi phí:** Khai phá tập dữ liệu Cost & Usage Report (CUR) để phân tích chi phí theo từng phòng ban/dự án, nhận diện các ngày chi phí đột biến (Cost Spikes) và quét các máy chủ lãng phí (CPU < 30%).
* **Tối ưu hóa & Thực thi hành động:** Thẩm định và đề xuất các chiến lược tối ưu phù hợp (*Right-Sizing*, *Schedule Stop*, *Reserved Instances*), lập bản báo cáo FinOps Report tổng thể và trực tiếp thực thi lệnh AWS CLI `terminate-instances` để cắt giảm chi phí lãng phí.
