# Bước 3: Khởi Chạy Prometheus & Cấu Hình Scrape Target

Prometheus sử dụng cơ chế kéo dữ liệu (Pull-based Model): Định kỳ mỗi chu kỳ (Scrape Interval), Prometheus sẽ gửi một HTTP GET request đến endpoint **/metrics** của ứng dụng mục tiêu để thu thập và lưu trữ số liệu vào cơ sở dữ liệu chuỗi thời gian (TSDB).

---

### 1. Tạo tệp cấu hình prometheus.yml

Tạo tệp cấu hình chỉ định chu kỳ thu thập 5 giây và địa chỉ của dịch vụ **order-api**:

```bash
cd /root/app-monitoring-lab
cat << 'EOF' > prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'order-api'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['localhost:3000']
EOF
cat prometheus.yml
```{{exec}}

---

### 2. Khởi chạy Prometheus Server bằng Docker

Khởi chạy container Prometheus chính thức với chế độ mạng `--network host` để Prometheus có thể kết nối trực tiếp đến localhost:3000 và mở giao diện Web trên cổng 9090:

```bash
docker run -d --name prometheus --network host -v /root/app-monitoring-lab/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest
```{{exec}}

Kiểm tra trạng thái container đang chạy:

```bash
docker ps | grep prometheus
```{{exec}}

---

### 3. Kiểm tra trạng thái Target qua API của Prometheus

Đợi 5 giây để Prometheus thực hiện lần scrape đầu tiên, sau đó truy vấn API để kiểm tra độ tin cậy của kết nối:

```bash
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health, lastScrape: .lastScrape}'
```{{exec}}

Trường `'health: "up"'` xác nhận Prometheus đã kết nối thành công tới dịch vụ **order-api** và đang đều đặn nạp các chỉ số telemetry vào hệ thống lưu trữ.

Nhấn **Check** để hoàn thành bước 3.
