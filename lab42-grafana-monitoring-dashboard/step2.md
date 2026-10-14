# Bước 2: Thiết Kế Dashboard Giám Sát Hạ Tầng (CPU, RAM & Network)

Trong bước này, bạn sẽ áp dụng chuẩn **Dashboard as Code** để xây dựng một bảng điều khiển giám sát hạ tầng máy chủ Linux chuyên nghiệp với các loại Panel: **Gauge** (đồng hồ đo tức thời) và **Time-Series** (đồ thị đường biến thiên theo thời gian).

---

### 1. Cơ Chế Dashboard Provisioning Trong Grafana

Để Grafana tự động nạp các tệp Dashboard JSON từ đĩa cứng mà không cần người dùng phải bấm "Import" thủ công, Grafana sử dụng cơ chế **Dashboard Provider** thông qua tệp YAML đặt tại `/etc/grafana/provisioning/dashboards/`.

Khởi tạo tệp khai báo Provider `/root/grafana-lab/provisioning/dashboards/dashboard-provider.yml`:

```bash
cat << 'EOF' > /root/grafana-lab/provisioning/dashboards/dashboard-provider.yml
apiVersion: 1

providers:
  - name: 'infrastructure-dashboards'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF
```

Khi Provider này hoạt động, bất kỳ tệp JSON nào nằm trong thư mục `/root/grafana-lab/dashboards/` (được mount vào `/var/lib/grafana/dashboards` trong container) sẽ tự động xuất hiện trong thư mục **Infrastructure** trên giao diện Grafana.

---

### 2. Thiết Kế Bộ Chỉ Số Hạ Tầng Cho Dashboard

Một Dashboard hạ tầng Linux chuẩn SRE gồm các thành phần trọng yếu:

| Tên Panel | Kiểu Panel | Công thức PromQL | Đơn vị (Unit) | Ngưỡng màu (Thresholds) |
| :--- | :--- | :--- | :--- | :--- |
| **CPU Usage** | `gauge` | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)` | `% (0-100)` | Xanh (<60%), Vàng (60-80%), Đỏ (>80%) |
| **RAM Usage** | `gauge` | `100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))` | `% (0-100)` | Xanh (<70%), Vàng (70-85%), Đỏ (>85%) |
| **CPU History** | `timeseries` | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)` | `%` | Biểu đồ đường biến thiên |
| **Network Throughput** | `timeseries` | In: `sum(rate(node_network_receive_bytes_total{device!~"lo\|veth.*"}[2m])) / 1024`<br/>Out: `sum(rate(node_network_transmit_bytes_total{device!~"lo\|veth.*"}[2m])) / 1024` | `KBs` | Inbound vs Outbound |

---

### 3. Khởi Tạo Tệp Schema JSON Cho Dashboard Hạ Tầng

Tạo tệp JSON schema hoàn chỉnh `/root/grafana-lab/dashboards/infrastructure-dashboard.json`:

```bash
cat << 'EOF' > /root/grafana-lab/dashboards/infrastructure-dashboard.json
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
      "title": "Current CPU Usage",
      "type": "gauge",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 },
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
      "title": "Current RAM Usage",
      "type": "gauge",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 },
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
      "title": "CPU Usage Trend",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 8 },
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "lineInterpolation": "smooth" },
          "unit": "percent"
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100)",
          "legendFormat": "CPU Busy %",
          "refId": "A"
        }
      ]
    },
    {
      "id": 4,
      "title": "Network Traffic (Inbound vs Outbound)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 8 },
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "lineInterpolation": "smooth" },
          "unit": "KBs"
        },
        "overrides": []
      },
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "sum(rate(node_network_receive_bytes_total{device!~\"lo|veth.*\"}[2m])) / 1024",
          "legendFormat": "Inbound (Receive)",
          "refId": "A"
        },
        {
          "datasource": { "type": "prometheus", "uid": "prometheus" },
          "expr": "sum(rate(node_network_transmit_bytes_total{device!~\"lo|veth.*\"}[2m])) / 1024",
          "legendFormat": "Outbound (Transmit)",
          "refId": "B"
        }
      ]
    }
  ],
  "refresh": "5s",
  "schemaVersion": 39,
  "style": "dark",
  "tags": ["infrastructure", "linux", "sre"],
  "time": { "from": "now-15m", "to": "now" },
  "timepicker": {},
  "timezone": "browser",
  "title": "Linux Host Infrastructure Overview",
  "uid": "linux-host-infra"
}
EOF
```

---

### 4. Tải Lại Dashboard & Kiểm Tra Kết Quả

Kích hoạt nạp lại Dashboards qua REST API của Grafana:

```bash
# Nạp lại danh sách Dashboard
curl -s -X POST -u admin:admin http://localhost:3000/api/admin/provisioning/dashboards/reload

# Kiểm tra danh sách Dashboard hiện có trên Grafana
curl -s -u admin:admin http://localhost:3000/api/search?type=dash-db | jq .
```

Mở trình duyệt truy cập `http://localhost:3000/d/linux-host-infra/linux-host-infrastructure-overview`. Bạn sẽ thấy một bảng điều khiển gồm 4 panel: 2 đồng hồ Gauge hiển thị % CPU/RAM sinh động và 2 đồ thị Time-series cập nhật mượt mà theo chu kỳ mỗi 5 giây!

---

### 5. Yêu Cầu Hoàn Thành Bước 2

1. Đã khởi tạo tệp Provider `/root/grafana-lab/provisioning/dashboards/dashboard-provider.yml`.
2. Đã lưu tệp schema `/root/grafana-lab/dashboards/infrastructure-dashboard.json` chứa các panel CPU/RAM Gauge và Time-series.
3. API Grafana `/api/search` hiển thị Dashboard có UID `linux-host-infra`.

Sau khi hoàn tất, nhấn **Check** để hệ thống tự động kiểm tra Bước 2.
