# Bước 2: Thiết Lập AWS Budgets & Cơ Chế Cảnh Báo Ngân Sách

Trong bước này, bạn sẽ tìm hiểu cơ chế hoạt động của **AWS Budgets**, cấu hình các quy tắc cảnh báo ngân sách đa tầng và kích hoạt hệ thống phát hiện nguy cơ vượt ngân sách (Cost Overrun).

---

## 1. Lý Thuyết: Chiến Lược Cảnh Báo Ngân Sách Trên Cloud

**AWS Budgets** cho phép bạn đặt trần chi phí theo tháng/quý và tự động bắn cảnh báo qua Email/Slack:

```
Ngân Sách Được Giao: $300 / tháng
  ├── Mức 80% ($240)   ──► Cảnh báo sớm (Warning) ──► Gửi tới Trưởng nhóm DevOps
  ├── Mức 100% ($300)  ──► Chạm trần ngân sách    ──► Gửi tới CTO & Quản lý dự án
  └── Forecast 110%    ──► Dự báo sẽ vượt trần   ──► Cảnh báo khẩn cấp (Critical)
```

Hai cơ chế kích hoạt cảnh báo:
* **`ACTUAL` (Thực chi):** Kích hoạt khi số tiền thực tế đã tiêu đạt đến ngưỡng phần trăm quy định.
* **`FORECASTED` (Dự báo xu hướng):** Sử dụng máy học phân tích tốc độ tiêu tiền trong tuần đầu tiên; nếu tốc độ này tiếp diễn sẽ làm vỡ ngân sách cuối tháng → Lập tức gửi cảnh báo sớm để can thiệp kịp thời!

---

## 2. Thực Hành

### 2.1 — Tạo File Cấu Hình AWS Budgets Đa Tầng

Tạo file cấu hình ngân sách tại `/opt/lab-data/budgets/config.json`, phân tầng từ cấp toàn công ty đến từng dự án:

```bash
cat << 'EOF' > /opt/lab-data/budgets/config.json
{
  "budgets": [
    {
      "name": "total-monthly-budget",
      "limit_usd": 300,
      "alerts": [
        {"threshold_pct": 80,  "type": "ACTUAL",    "notify": "devops-lead@company.com"},
        {"threshold_pct": 100, "type": "ACTUAL",    "notify": "cto@company.com"},
        {"threshold_pct": 110, "type": "FORECAST",  "notify": "cto@company.com"}
      ]
    },
    {
      "name": "project-e-commerce",
      "limit_usd": 150,
      "filter": {"Project": "e-commerce"},
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL", "notify": "pm-ecommerce@company.com"}
      ]
    },
    {
      "name": "project-data-platform",
      "limit_usd": 80,
      "filter": {"Project": "data-platform"},
      "alerts": [
        {"threshold_pct": 80, "type": "ACTUAL", "notify": "data-lead@company.com"}
      ]
    }
  ]
}
EOF

echo "✅ Đã tạo cấu hình AWS Budgets thành công!"
```{{exec}}

---

### 2.2 — Cú Pháp Lệnh AWS CLI Chuẩn Để Tạo Budget Trên AWS

> [!NOTE]
> Trong môi trường AWS thật, bạn sử dụng lệnh `aws budgets create-budget` để đẩy cấu hình này lên:

```bash
# Cú pháp tham khảo khi vận hành trên AWS thật:
# aws budgets create-budget \
#   --account-id 123456789012 \
#   --budget file:///opt/lab-data/budgets/budget-spec.json \
#   --notifications-with-subscribers file:///opt/lab-data/budgets/notifications.json
```

---

### 2.3 — Đánh Giá Nguy Cơ Vượt Ngân Sách (Budget Alert Evaluation)

Chạy script đánh giá để đối chiếu dữ liệu chi phí thực tế 30 ngày vừa qua với các ngưỡng ngân sách bạn đã đặt:

```bash
/opt/lab-data/budgets/eval-budgets.py
```{{exec}}

Quan sát terminal: Bạn sẽ thấy hệ thống đánh giá từng rule, tính toán tỷ lệ thực chi (%) và tự động phát hiện những rule bị **🚨 KÍCH HOẠT CẢNH BÁO**!

---

## 3. Bài Tập Thử Thách

**Yêu cầu:** Bổ sung thêm một cấu hình Budget mới cho dự án nội bộ `internal-tools`:
* Tên: `"project-internal-tools"`
* Hạn mức chi phí: `"limit_usd": 50`
* Bộ lọc: `"filter": {"Project": "internal-tools"}`
* Quy tắc cảnh báo: Ngưỡng `80%`, loại `ACTUAL`, gửi tới `"devops-team@company.com"`.

Thêm đoạn cấu hình trên vào mảng `"budgets"` trong file `/opt/lab-data/budgets/config.json`, sau đó chạy lại `/opt/lab-data/budgets/eval-budgets.py`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
