# Xin Chúc Mừng! Bạn Đã Hoàn Thành Lab 40

Bạn đã làm chủ toàn bộ nền tảng thu thập dữ liệu (Metrics Ingestion) chuẩn công nghiệp của **Prometheus** và **Exporters**.

---

## 1. Bảng Tổng Hợp Kiến Thức Cốt Lõi

| Thành phần | Cổng mặc định | Vai trò chính |
| :--- | :--- | :--- |
| **Node Exporter** | `9100` | Đọc kernel `/proc`, `/sys` để đo CPU, RAM, Disk, Network của máy chủ Linux. |
| **Redis Exporter** | `9121` | Kết nối CSDL Redis để đo số clients, bộ nhớ, lệnh thực thi (`INFO`). |
| **Prometheus Server** | `9090` | Kéo dữ liệu theo chu kỳ (Pull), lưu trữ vào TSDB và cung cấp API truy vấn. |
| **Lifecycle API** | `/-/reload` | Nạp lại cấu hình `prometheus.yml` tức thời mà không gây downtime. |

---

## 2. Bảng Tra Cứu Cú Pháp Cấu Hình (Cheat Sheet)

```yaml
global:
  scrape_interval: 15s      # Chu kỳ cào dữ liệu (mặc định 1m, production thường đặt 10s-30s)
  evaluation_interval: 15s  # Chu kỳ đánh giá alerting rules

scrape_configs:
  - job_name: 'ten-dich-vu'
    scrape_interval: 5s     # Có thể ghi đè chu kỳ riêng cho từng job
    metrics_path: '/metrics'# Đường dẫn endpoint mặc định
    static_configs:
      - targets: ['host1:9100', 'host2:9100']
        labels:             # Metadata tĩnh gắn vào tất cả chuỗi thời gian của target
          env: 'production'
          region: 'ap-southeast-1'
```

---

## 3. Bước Tiếp Theo

Hiện tại, kho lưu trữ TSDB của bạn đã ngập tràn các chuỗi thời gian quý giá từ hệ điều hành và cơ sở dữ liệu. Nhưng làm thế nào để:
- Tính toán chính xác **phần trăm (%) CPU** đang sử dụng?
- Phát hiện máy chủ sắp hết RAM?
- Đo lường lưu lượng mạng theo giây?

Hãy tiếp tục bước sang bài học và bài thực hành tiếp theo:
**"Lab 41: Phân Tích Hệ Thống Bằng PromQL"**!
