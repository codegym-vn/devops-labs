# Bước 2: Thiết lập AWS Budgets và cảnh báo ngân sách

## Lý thuyết

**AWS Budgets** cho phép đặt ngưỡng chi phí và nhận cảnh báo trước khi vượt budget:

```
Budget $100/tháng
    │
    ├── Alert 1: 80% ($80) → Email WARNING
    ├── Alert 2: 100% ($100) → Email CRITICAL
    └── Alert 3: 110% (forecast) → Email FORECAST
```

**Loại Budget:**
- **Cost Budget**: Dựa trên chi phí thực tế (USD)
- **Usage Budget**: Dựa trên số giờ sử dụng (EC2 hours, etc.)
- **Savings Plans**: Theo % sử dụng Savings Plans

---

## Thử thách thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Tạo Budget tổng thể cho tất cả Cloud resources

```bash
ACCOUNT_ID="000000000000"

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
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "devops-team@company.com"}]
    },
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "cto@company.com"}]
    }
  ]'

echo "✅ Budget 'monthly-cloud-budget' đã tạo ($100/tháng)"
```

### 2.2 — Tạo Budget riêng theo Project

```bash
for PROJECT in "e-commerce" "data-platform" "internal-tools"; do
  LIMIT=$([ "$PROJECT" = "e-commerce" ] && echo "60" || ([ "$PROJECT" = "data-platform" ] && echo "30" || echo "10"))

  aws budgets create-budget \
    --account-id $ACCOUNT_ID \
    --budget "{
      \"BudgetName\": \"budget-${PROJECT}\",
      \"BudgetLimit\": {\"Amount\": \"${LIMIT}\", \"Unit\": \"USD\"},
      \"TimeUnit\": \"MONTHLY\",
      \"BudgetType\": \"COST\",
      \"CostFilters\": {\"TagKeyValue\": [\"user:Project\$${PROJECT}\"]}
    }" \
    --notifications-with-subscribers "[{
      \"Notification\": {
        \"NotificationType\": \"ACTUAL\",
        \"ComparisonOperator\": \"GREATER_THAN\",
        \"Threshold\": 80,
        \"ThresholdType\": \"PERCENTAGE\"
      },
      \"Subscribers\": [{\"SubscriptionType\": \"EMAIL\", \"Address\": \"team@company.com\"}]
    }]"

  echo "✅ Budget '$PROJECT': \$$LIMIT/tháng"
done
```

### 2.3 — Xem tất cả budgets đã tạo

```bash
echo "=== Danh sách Budgets ==="
aws budgets describe-budgets --account-id $ACCOUNT_ID \
  --query 'Budgets[*].{Name:BudgetName,Limit:BudgetLimit.Amount,Currency:BudgetLimit.Unit}' \
  --output table
```

---

## Câu hỏi kiểm tra hiểu biết

1. Tại sao cần cả **ACTUAL** alert và **FORECASTED** alert? Khi nào dùng loại nào?
2. Một Budget có thể theo dõi chi phí của **nhiều tag** cùng lúc không?
3. Ngoài Email, AWS Budgets còn có thể trigger **hành động tự động** nào? (gợi ý: Budget Actions)
