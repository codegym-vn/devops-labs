# Bước 3: Phân tích Cost & Usage Report

## Lý thuyết

**Cost & Usage Report (CUR)** là báo cáo chi phí chi tiết nhất của AWS — CSV file chứa từng dòng chi phí theo giờ, theo resource, theo tag. Trong thực tế, CUR được export vào S3 và phân tích bằng Athena hoặc QuickSight.

Trong lab này, chúng ta dùng **Python script** để phân tích file CUR mẫu đã chuẩn bị sẵn.

---

## Thử thách thực hành

### 3.1 — Khám phá dataset CUR

```bash
echo "=== Xem cấu trúc file CUR ==="
head -5 /opt/lab-data/cost-usage-report.csv
echo ""
echo "Tổng số dòng: $(wc -l < /opt/lab-data/cost-usage-report.csv)"
echo "Khoảng thời gian: $(awk -F',' 'NR>1{print $1}' /opt/lab-data/cost-usage-report.csv | sort | head -1) đến $(awk -F',' 'NR>1{print $1}' /opt/lab-data/cost-usage-report.csv | sort | tail -1)"
```

### 3.2 — Phân tích chi phí theo Service

```bash
echo "=== Chi phí theo AWS Service (tháng 9/2024) ==="
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by ProductName
```

### 3.3 — Phân tích chi phí theo Project (Tag)

```bash
echo "=== Chi phí theo Project ==="
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by Project
```

### 3.4 — Phân tích chi phí theo Environment

```bash
echo "=== Chi phí theo Environment ==="
python3 /opt/lab-data/analyze-cost.py \
  --file /opt/lab-data/cost-usage-report.csv \
  --group-by Environment
```

### 3.5 — Tìm ngày có chi phí cao nhất

```bash
echo "=== Top 5 ngày có chi phí cao nhất ==="
python3 << 'PYEOF'
import csv
from collections import defaultdict

daily = defaultdict(float)
with open("/opt/lab-data/cost-usage-report.csv") as f:
    for row in csv.DictReader(f):
        daily[row["UsageStartDate"]] += float(row["Cost"])

top5 = sorted(daily.items(), key=lambda x: -x[1])[:5]
print(f"{'Ngày':<15} {'Chi phí (USD)':>15}")
print("─" * 32)
for date, cost in top5:
    print(f"  {date:<13} ${cost:>13.2f}")
PYEOF
```

### 3.6 — Phân tích chi phí EC2 theo Owner

```bash
echo "=== Chi phí EC2 theo Owner team ==="
python3 << 'PYEOF'
import csv
from collections import defaultdict

totals = defaultdict(float)
grand = 0
with open("/opt/lab-data/cost-usage-report.csv") as f:
    for row in csv.DictReader(f):
        if "EC2" in row["ProductName"]:
            owner = row.get("Owner", "Unknown")
            totals[owner] += float(row["Cost"])
            grand += float(row["Cost"])

print(f"\n{'Team':<20} {'EC2 Cost':>12} {'%':>8}")
print("─" * 42)
for k, v in sorted(totals.items(), key=lambda x: -x[1]):
    print(f"  {k:<18} ${v:>10.2f} {v/grand*100:>7.1f}%")
print(f"  {'TỔNG':<18} ${grand:>10.2f}")
PYEOF
```

---

## Câu hỏi kiểm tra hiểu biết

1. Service nào có chi phí cao nhất? Có hợp lý không?
2. Environment nào tốn nhiều nhất? Tỷ lệ production:staging:dev có cân đối không?
3. Trong thực tế, CUR được phân tích bằng công cụ nào thay vì Python script?
