# Bước 2: Budget Alerts — Cảnh báo ngân sách

## Lý thuyết

**Budget Alert** là cơ chế cảnh báo trước khi vượt ngân sách:

```
Budget: $100/tháng
  ├── 80% ($80) → Cảnh báo sớm → team trưởng
  ├── 100% ($100) → Vượt ngân sách → CTO
  └── Forecast 120% → Dự báo sẽ vượt → Alert tự động
```

Hai loại alert:
- **ACTUAL**: dựa trên chi phí đã phát sinh
- **FORECASTED**: dự báo chi phí cuối tháng dựa trên trend hiện tại

Budget tốt nên phân loại theo nhiều cấp:
- Budget tổng thể (toàn công ty)
- Budget theo Project
- Budget theo Team/CostCenter

---

## Thực hành

### 2.1 — Tạo cấu hình Budget

```bash
mkdir -p /opt/lab-data/budgets

cat > /opt/lab-data/budgets/config.json << 'EOF'
{
  "budgets": [
    {
      "name": "total-monthly",
      "limit_usd": 300,
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL",    "notify": "devops-team@company.com"},
        {"threshold_pct": 100, "type": "ACTUAL",   "notify": "cto@company.com"},
        {"threshold_pct": 110, "type": "FORECAST", "notify": "cto@company.com"}
      ]
    },
    {
      "name": "project-e-commerce",
      "limit_usd": 150,
      "filter": {"Project": "e-commerce"},
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL", "notify": "team-backend@company.com"}
      ]
    },
    {
      "name": "project-data-platform",
      "limit_usd": 80,
      "filter": {"Project": "data-platform"},
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL", "notify": "team-data@company.com"}
      ]
    },
    {
      "name": "project-internal-tools",
      "limit_usd": 70,
      "filter": {"Project": "internal-tools"},
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL", "notify": "team-devops@company.com"}
      ]
    }
  ]
}
EOF

echo "✅ Budget config: /opt/lab-data/budgets/config.json"
cat /opt/lab-data/budgets/config.json | python3 -m json.tool | head -20
```

### 2.2 — Script kiểm tra budget và gửi alert

```bash
cat > /opt/lab-data/budgets/check-budget.py << 'EOF'
#!/usr/bin/env python3
"""
Budget checker — chạy hàng ngày (cron job)
Tương đương AWS Budgets / GCP Budget Alerts / Azure Cost Alerts
"""
import json, csv
from collections import defaultdict
from datetime import datetime

# Đọc config
with open("/opt/lab-data/budgets/config.json") as f:
    config = json.load(f)

# Đọc chi phí thực tế từ CUR
actual_costs = defaultdict(float)
project_costs = defaultdict(float)

with open("/opt/lab-data/cost-usage-report.csv") as f:
    for row in csv.DictReader(f):
        cost = float(row["Cost"])
        actual_costs["total"] += cost
        project_costs[row.get("Project", "unknown")] += cost

print(f"=== Budget Alert Report — {datetime.now().strftime('%Y-%m-%d')} ===\n")

for budget in config["budgets"]:
    name = budget["name"]
    limit = budget["limit_usd"]

    # Lấy chi phí thực tế tương ứng
    if "filter" in budget:
        proj = budget["filter"].get("Project")
        actual = project_costs.get(proj, 0)
    else:
        actual = actual_costs["total"]

    pct = (actual / limit) * 100

    print(f"Budget: {name}")
    print(f"  Giới hạn: ${limit:.0f}/tháng")
    print(f"  Thực tế : ${actual:.2f} ({pct:.0f}%)")
    print(f"  Thanh:   [{'█' * int(pct/5):<20}] {pct:.0f}%")

    for alert in budget["alerts"]:
        threshold = alert["threshold_pct"]
        alert_type = alert["type"]
        notify = alert["notify"]

        if pct >= threshold and alert_type == "ACTUAL":
            print(f"  🔴 ALERT {threshold}%: Gửi email → {notify}")
        elif pct >= threshold * 0.9 and alert_type == "FORECAST":
            print(f"  🟡 FORECAST ALERT: Dự báo vượt {threshold}% → {notify}")
        else:
            print(f"  ✅ Alert {threshold}% ({alert_type}): chưa kích hoạt")
    print()
EOF

python3 /opt/lab-data/budgets/check-budget.py
```

### 2.3 — Thiết lập cron job kiểm tra budget hàng ngày

```bash
# Tương đương AWS Budget scheduled check
echo "0 9 * * * root python3 /opt/lab-data/budgets/check-budget.py >> /var/log/budget-check.log 2>&1" \
  > /etc/cron.d/budget-check

echo "✅ Cron job: budget check mỗi ngày lúc 9:00"
cat /etc/cron.d/budget-check

echo ""
echo "Chạy thử ngay:"
python3 /opt/lab-data/budgets/check-budget.py
```

---

## Tương đương trên Cloud

| Lab (Python + Cron) | AWS | GCP | Azure |
|--------------------|-----|-----|-------|
| `config.json` budgets | AWS Budgets | Cloud Billing Budgets | Azure Budgets |
| Email alert | SNS notification | Pub/Sub notification | Action Group |
| Cron job check | Scheduled Lambda | Cloud Scheduler | Logic Apps |
| Forecast alert | Forecasted budget | Forecasted budget | Forecasted budget |

---

## Câu hỏi

1. Khi nào cần ACTUAL alert, khi nào cần FORECASTED alert?
2. Budget nên đặt ở mức nào — bằng đúng mức dự báo hay thấp hơn?
3. Nếu budget vượt — ngoài email, hành động tự động nào nên kích hoạt?

---

## 🎯 Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Thêm budget cho team security vừa thành lập vào file `config.json`.

Budget cần có:
- `name`: `"project-security-tools"`
- `limit_usd`: `25`
- Filter theo `Project=security-tools`
- Alert tại 90% (ACTUAL), gửi đến `team-security@company.com`

**Gợi ý khi bí:**
- Mở `/opt/lab-data/budgets/config.json` và thêm entry mới vào mảng `budgets`
- Xem format của entry `project-internal-tools` làm mẫu
- Validate: `python3 -m json.tool /opt/lab-data/budgets/config.json`

> Nhấn **Check** khi hoàn thành.
