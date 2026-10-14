# Bước 4: Tối Ưu Dashboard Với Variables (Dynamic Templating) & Xuất Bản

Trong môi trường thực tế với hàng chục microservices hoặc hàng trăm server instances, việc viết cứng (hardcode) nhãn `path` hay `instance` vào từng Panel sẽ khiến hệ thống bảng điều khiển trở nên cồng kềnh, khó bảo trì.

Kỹ thuật **Variables (Biến số & Dynamic Templating)** là tính năng cốt lõi của Grafana, cho phép tạo thanh thả xuống (Dropdown Filter) trên đầu trang để người xem có thể lọc dữ liệu theo từng dịch vụ, môi trường hoặc endpoint theo thời gian thực.

---

### 1. Nguyên Lý Hoạt Động Của Query Variable

Grafana hỗ trợ hàm đặc thù **`label_values()`** khi làm việc với Prometheus DataSource:
- `label_values(http_requests_total, path)`: Tự động truy vấn Prometheus và trả về danh sách tất cả các giá trị duy nhất của nhãn `path` (ví dụ: `/api/orders`, `/api/products`, `/api/users`).
- Biến này được đặt tên là `path`. Trong các câu truy vấn PromQL của từng Panel, bạn chỉ cần thay thế giá trị cố định bằng biến **`$path`**:
  ```promql
  sum(rate(http_requests_total{path=~"$path"}[2m]))
  ```
- Khi người dùng chọn "All" hoặc nhiều endpoint cùng lúc, biểu thức chính quy Regex `=~"$path"` sẽ tự động mở rộng (ví dụ: `/api/orders|/api/products`), giúp toàn bộ bảng điều khiển cập nhật đồng bộ.

---

### 2. Cấu Trúc Khai Báo Templating Trong JSON Schema

Phần `templating` trong schema JSON của Dashboard được định nghĩa như sau:

```json
"templating": {
  "list": [
    {
      "current": { "selected": true, "text": "All", "value": "$__all" },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "definition": "label_values(http_requests_total, path)",
      "hide": 0,
      "includeAll": true,
      "allValue": ".*",
      "multi": true,
      "name": "path",
      "label": "API Endpoint",
      "query": { "query": "label_values(http_requests_total, path)", "refId": "StandardVariableQuery" },
      "type": "query"
    }
  ]
}
```

---

### 3. Khởi Tạo Dashboard Tổng Hợp Production Hoàn Chỉnh

Hãy tạo Dashboard tổng hợp cấp doanh nghiệp tại tệp `/root/grafana-lab/dashboards/production-system-overview.json`. Bảng điều khiển này kết hợp cả giám sát hạ tầng và ứng dụng, đồng thời áp dụng Dynamic Templating:

```bash
cat << 'EOF' > /root/grafana-lab/dashboards/production-system-overview.json
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
      "title": "Host CPU Usage",
      "type": "gauge",
      "gridPos": { "h": 6, "w": 6, "x": 0, "y": 0 },
      "fieldConfig": {
        "defaults": {
          "min": 0,
          "max": 100,
          "unit": "percent",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "#EAB839", "value": 60 },
              { "color": "red", "value": 80 }
            ]
          }
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100)",
          "refId": "A"
        }
      ]
    },
    {
      "id": 2,
      "title": "Host RAM Usage",
      "type": "gauge",
      "gridPos": { "h": 6, "w": 6, "x": 6, "y": 0 },
      "fieldConfig": {
        "defaults": {
          "min": 0,
          "max": 100,
          "unit": "percent",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "#EAB839", "value": 70 },
              { "color": "red", "value": 85 }
            ]
          }
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))",
          "refId": "A"
        }
      ]
    },
    {
      "id": 3,
      "title": "Active Users",
      "type": "stat",
      "gridPos": { "h": 6, "w": 6, "x": 12, "y": 0 },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "blue", "value": null },
              { "color": "green", "value": 60 }
            ]
          }
        },
        "overrides": []
      },
      "options": { "graphMode": "area" },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "active_users_total",
          "refId": "A"
        }
      ]
    },
    {
      "id": 4,
      "title": "Filter: Error Rate % (Endpoint: $path)",
      "type": "stat",
      "gridPos": { "h": 6, "w": 6, "x": 18, "y": 0 },
      "fieldConfig": {
        "defaults": {
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
      "options": { "graphMode": "area" },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "(sum(rate(http_requests_total{path=~\"$path\",status=~\"5..\"}[2m])) / sum(rate(http_requests_total{path=~\"$path\"}[2m]))) * 100",
          "refId": "A"
        }
      ]
    },
    {
      "id": 5,
      "title": "Filtered Throughput RPS by Selected Endpoints ($path)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 6 },
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
          "expr": "sum by (path) (rate(http_requests_total{path=~\"$path\"}[2m]))",
          "legendFormat": "{{path}}",
          "refId": "A"
        }
      ]
    },
    {
      "id": 6,
      "title": "Filtered p95 Latency SLA by Selected Endpoints ($path)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 6 },
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
          "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{path=~\"$path\"}[2m])) by (le, path))",
          "legendFormat": "p95 {{path}}",
          "refId": "A"
        }
      ]
    }
  ],
  "refresh": "5s",
  "schemaVersion": 39,
  "style": "dark",
  "tags": ["production", "sre", "overview", "templating"],
  "templating": {
    "list": [
      {
        "current": { "selected": true, "text": "All", "value": "$__all" },
        "datasource": { "type": "prometheus", "uid": "prometheus" },
        "definition": "label_values(http_requests_total, path)",
        "hide": 0,
        "includeAll": true,
        "allValue": ".*",
        "multi": true,
        "name": "path",
        "label": "API Endpoint",
        "query": { "query": "label_values(http_requests_total, path)", "refId": "StandardVariableQuery" },
        "refresh": 1,
        "type": "query"
      }
    ]
  },
  "time": { "from": "now-15m", "to": "now" },
  "timepicker": {},
  "timezone": "browser",
  "title": "Production System Overview",
  "uid": "prod-system-overview"
}
EOF
```

---

### 4. Tải Lại & Trải Nghiệm Dropdown Filter Trên Web UI

Thực thi lệnh reload Provisioning:

```bash
# Nạp lại danh sách Dashboard
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload

# Kiểm tra trường templating của Dashboard qua API
curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/prod-system-overview | jq '.dashboard.templating.list[0] | {name: .name, query: .definition}'
```

Mở trình duyệt truy cập: `http://localhost:3000/d/prod-system-overview/production-system-overview`.
Trên góc trên bên trái của bảng điều khiển, bạn sẽ thấy dropdown **API Endpoint**:
- Bấm chọn riêng `/api/orders`: Tất cả các biểu đồ RPS, Latency và Error Rate sẽ chỉ hiển thị duy nhất dữ liệu của đơn hàng.
- Bấm chọn `/api/products` hoặc chọn đồng thời nhiều endpoint: Các biểu đồ tự động cập nhật ngay lập tức mà không cần tải lại trang.

---

### 5. Yêu Cầu Hoàn Thành Bước 4

1. Tệp schema `/root/grafana-lab/dashboards/production-system-overview.json` được tạo thành công với UID `prod-system-overview`.
2. Dashboard chứa khai báo `templating` với biến `path` truy vấn từ `label_values(http_requests_total, path)`.
3. Grafana REST API trả về Dashboard `prod-system-overview` với đầy đủ cấu hình.

Sau khi hoàn tất, nhấn **Check** để hoàn thành bài thực hành!
