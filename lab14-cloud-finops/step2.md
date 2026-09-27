# Bước 2: Thiết lập AWS Budgets

## Lý thuyết

**AWS Budgets**: đặt ngưỡng chi phí và nhận cảnh báo tự động.

```
Budget $100/tháng
  ├── 80%  ($80)  → Email cảnh báo sớm
  ├── 100% ($100) → Email vượt ngân sách
  └── Forecast    → Cảnh báo dự báo sẽ vượt
```

Các loại Budget: **Cost** (USD thực tế) · **Usage** (giờ dùng EC2) · **Savings Plans** (% tận dụng)

---

## Thực hành

```bash
source /tmp/lab-env.sh
ACCOUNT_ID="000000000000"
```

### 2.1 — Budget tổng thể ($100/tháng)

```bash
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "monthly-cloud-budget",
    "BudgetLimit": {"Amount": "100", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80, "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "devops-team@company.com"}]
    },
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100, "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cto@company.com"}]
    }
  ]'

echo "✅ monthly-cloud-budget: $100/tháng"
```

### 2.2 — Budget theo từng Project

```bash
for PROJECT in "e-commerce:60" "data-platform:30" "internal-tools:10"; do
  NAME="${PROJECT%%:*}"
  LIMIT="${PROJECT##*:}"

  aws budgets create-budget \
    --account-id $ACCOUNT_ID \
    --budget "{
      \"BudgetName\": \"budget-${NAME}\",
      \"BudgetLimit\": {\"Amount\": \"${LIMIT}\", \"Unit\": \"USD\"},
      \"TimeUnit\": \"MONTHLY\",
      \"BudgetType\": \"COST\"
    }" \
    --notifications-with-subscribers "[{
      \"Notification\": {
        \"NotificationType\": \"ACTUAL\",
        \"ComparisonOperator\": \"GREATER_THAN\",
        \"Threshold\": 80, \"ThresholdType\": \"PERCENTAGE\"
      },
      \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"team@company.com\"}]
    }]"

  echo "✅ budget-${NAME}: \$${LIMIT}/tháng"
done
```

### 2.3 — Xem danh sách Budgets

```bash
aws budgets describe-budgets --account-id $ACCOUNT_ID \
  --query 'Budgets[*].{Name:BudgetName,Limit:BudgetLimit.Amount}' \
  --output table
```

---

## Câu hỏi

1. Khi nào cần ACTUAL alert, khi nào cần FORECASTED alert?
2. Budget có thể lọc theo nhiều tag cùng lúc không?
3. Ngoài Email, Budgets còn có thể trigger hành động tự động nào?
