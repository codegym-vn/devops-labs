# Bước 3: Phân tích Cost & Usage Report

## Lý thuyết

**Cost & Usage Report (CUR)**: file CSV/Parquet chứa toàn bộ chi phí theo giờ — service, tag, resource, region. Đây là nguồn dữ liệu chính xác nhất để phân tích FinOps.

Dataset lab: `cost-usage-report.csv` (~400 dòng, 30 ngày, 5 services).

---

## Thực hành

```bash
# Xem cấu trúc file
head -3 /opt/lab-data/cost-usage-report.csv
echo "Tổng dòng: $(wc -l < /opt/lab-data/cost-usage-report.csv)"
```

### 3.1 — Breakdown chi phí theo Service

```bash
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by ProductName
```

### 3.2 — Breakdown theo Project

```bash
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by Project
```

### 3.3 — Breakdown theo Environment

```bash
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by Environment
```

### 3.4 — Tìm ngày chi phí cao bất thường

```bash
python3 << 'EOF'
import csv
from collections import defaultdict

daily = defaultdict(float)
with open("/opt/lab-data/cost-usage-report.csv") as f:
    for row in csv.DictReader(f):
        daily[row["UsageStartDate"]] += float(row["Cost"])

avg = sum(daily.values()) / len(daily)
print(f"Chi phí trung bình/ngày: ${avg:.2f}")
print("\nNgày cao bất thường (>150% trung bình):")
for date, cost in sorted(daily.items()):
    flag = "  SPIKE" if cost > avg * 1.5 else ""
    print(f"  {date}: ${cost:.2f}{flag}")
EOF
```

---

## Câu hỏi

1. Tại sao dùng CUR thay vì chỉ xem tổng hóa đơn cuối tháng?
2. Phân tích chi phí theo `Owner` tag giúp gì trong quy trình chargeback?
3. Bạn sẽ tự động hóa báo cáo CUR này như thế nào (cron job, Lambda)?

---

##  Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Tìm và ghi ra file `/tmp/top-service.txt` service tốn chi phí nhiều nhất trong 30 ngày, theo format:

```
Top service by cost:
Service: <tên service>
Total cost: $<số tiền>
% of total: <phần trăm>%
```

**Gợi ý khi bí:**
- Dùng `python3 /opt/lab-data/analyze-cost.py --group-by ProductName` để xem breakdown
- Xử lý output bằng Python hoặc awk để tìm max
- Tính `% of total = service_cost / total_cost * 100`

> Nhấn **Check** khi hoàn thành.
