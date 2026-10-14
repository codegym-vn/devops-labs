# Bước 3: Trực Quan Hóa Số Liệu Ứng Dụng Theo Mô Hình RED

Một lỗi phổ biến của các kỹ sư khi xây dựng Dashboard là chỉ tập trung vào tài nguyên máy chủ (CPU/RAM). Khi máy chủ còn dư 80% RAM, người dùng vẫn có thể đang gặp sự cố nghẽn kết nối Database hoặc lỗi 500 hàng loạt.

Để giám sát trải nghiệm người dùng thực tế và cam kết SLA/SLO, chúng ta xây dựng Dashboard theo mô hình **RED**:
- **R (Rate):** Lưu lượng truy cập (Requests per Second - RPS) phân loại theo từng Endpoint.
- **E (Errors):** Tỷ lệ lỗi 5xx trên tổng số request.
- **D (Duration):** Độ trễ phân vị p95 Percentile theo dõi thời gian phản hồi của dịch vụ.

---

### 1. Thiết Kế Bộ Chỉ Số RED & Panels Trực Quan

| Tên Panel | Kiểu Panel | Công thức PromQL | Đơn vị & Chức năng |
| :--- | :--- | :--- | :--- |
| **Active Users** | `stat` | `active_users_total` | Hiển thị số người dùng trực tuyến tức thời kèm mini sparkline |
| **Error Rate %** | `stat` | `(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100` | Cảnh báo đổi màu: Xanh (<2%), Vàng (2-5%), Đỏ (>5%) |
| **Throughput by Path** | `timeseries` | `sum by (path) (rate(http_requests_total[2m]))` | Đồ thị đường thể hiện RPS của từng API endpoint (`/api/orders`, `/api/products`...) |
| **p95 Latency SLA** | `timeseries` | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))` | Độ trễ 95th Percentile tính bằng giây (`s`) |

---

### 2. Khởi Tạo Tệp Schema JSON Cho Dashboard RED

Tạo tệp `/root/grafana-lab/dashboards/application-red-dashboard.json`:

```bash
cat << 'EOF' > /root/grafana-lab/dashboards/application-red-dashboard.json
{
  "annotations": { "list": [] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "id": 1,
      "title": "Active Users Online",
      "type": "stat",
      "gridPos": { "h": 6, "w": 12, "x": 0, "y": 0 },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "blue", "value": null },
              { "color": "green", "value": 50 }
            ]
          }
        },
        "overrides": []
      },
      "options": {
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "active_users_total",
          "refId": "A"
        }
      ]
    },
    {
      "id": 2,
      "title": "5xx Server Error Rate (%)",
      "type": "stat",
      "gridPos": { "h": 6, "w": 12, "x": 12, "y": 0 },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "unit": "percent",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "#EAB839", "value": 2 },
              { "color": "red", "value": 5 }
            ]
          }
        },
        "overrides": []
      },
      "options": {
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "(sum(rate(http_requests_total{status=~\"5..\"}[2m])) / sum(rate(http_requests_total[2m]))) * 100",
          "refId": "A"
        }
      ]
    },
    {
      "id": 3,
      "title": "API Throughput (Requests per Second by Path)",
      "type": "timeseries",
      "gridPos": { "h": 9, "w": 12, "x": 0, "y": 6 },
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "lineInterpolation": "smooth" },
          "unit": "reqps"
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "sum by (path) (rate(http_requests_total[2m]))",
          "legendFormat": "{{path}}",
          "refId": "A"
        }
      ]
    },
    {
      "id": 4,
      "title": "Service Latency (95th Percentile SLA)",
      "type": "timeseries",
      "gridPos": { "h": 9, "w": 12, "x": 12, "y": 6 },
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "lineInterpolation": "smooth" },
          "unit": "s"
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))",
          "legendFormat": "p95 Latency",
          "refId": "A"
        }
      ]
    }
  ],
  "refresh": "5s",
  "schemaVersion": 39,
  "style": "dark",
  "tags": ["application", "ecommerce", "red", "sla"],
  "time": { "from": "now-15m", "to": "now" },
  "timepicker": {},
  "timezone": "browser",
  "title": "Ecommerce API RED Monitoring",
  "uid": "ecommerce-app-red"
}
EOF
```

---

### 3. Nạp Lại Dashboard & Chiêm Ngưỡng Giao Diện RED

Gọi API để Grafana tự động nạp Dashboard mới:

```bash
# Nạp lại danh sách Dashboard
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload

# Kiểm tra qua API
curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/ecommerce-app-red | jq .dashboard.title
```

Mở trình duyệt truy cập `http://localhost:3000/d/ecommerce-app-red/ecommerce-api-red-monitoring`.
Bạn sẽ thấy giao diện giám sát ứng dụng trực quan:
- Thẻ **Active Users** đổi màu và hiển thị vùng biểu đồ sóng.
- Thẻ **Error Rate %** cảnh báo tỷ lệ lỗi 5xx.
- Biểu đồ **Throughput** phân rã từng endpoint bằng màu sắc khác nhau.
- Biểu đồ **p95 Latency** giúp phát hiện tức thì các thời điểm dịch vụ bị gián đoạn hoặc phản hồi chậm chạp.

---

### 4. Yêu Cầu Hoàn Thành Bước 3

1. Tệp schema `/root/grafana-lab/dashboards/application-red-dashboard.json` được tạo thành công với cấu trúc các Panel theo mô hình RED.
2. Grafana API trả về tiêu đề Dashboard hợp lệ cho UID `ecommerce-app-red`.

Sau khi hoàn tất, nhấn **Check** để hệ thống tự động kiểm tra Bước 3.
