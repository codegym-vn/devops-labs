# Bước 3: Cấu Hình Scrape Targets Đa Nguồn Trong prometheus.yml

Sau khi đã có 2 Exporters chạy độc lập, bước tiếp theo là cấu hình để **Prometheus Server** tự động định kỳ kéo dữ liệu về kho lưu trữ tập trung.

Hiện tại chúng ta có 3 nguồn dữ liệu:
1. **`localhost:9090`**: Chính Prometheus Server (Self-monitoring).
2. **`localhost:9100`**: Node Exporter (Hạ tầng OS).
3. **`localhost:9121`**: Redis Exporter (Dịch vụ CSDL).

---

### 1. Soạn Thảo Tệp Cấu Hình prometheus.yml

Tạo tệp cấu hình **/root/prometheus-lab/prometheus.yml** định nghĩa chu kỳ kéo mẫu (Scrape Interval = 5s) và 3 tác vụ thu thập (Scrape Jobs):

```bash
cat << 'EOF' > /root/prometheus-lab/prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          environment: 'production'
          datacenter: 'hanoi-dc1'

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']
        labels:
          environment: 'production'
          service: 'cache-layer'
EOF
cat /root/prometheus-lab/prometheus.yml
```

> [!NOTE]
> Nhãn khai báo tĩnh (`labels: environment: 'production'`) là cực kỳ quan trọng trong doanh nghiệp. Khi có hàng trăm server, các nhãn này giúp kỹ sư phân loại và nhóm số liệu theo môi trường, cụm mạng hoặc datacenter.

---

### 2. Khởi Chạy Prometheus Server

Khởi chạy container Prometheus và gắn kèm tệp cấu hình vừa tạo. 

> [!IMPORTANT]
> Cờ `--web.enable-lifecycle` bắt buộc phải được kích hoạt để mở endpoint `/-/reload`, cho phép nạp lại cấu hình động ở Bước 4 mà không cần khởi động lại container:

```bash
docker run -d --name prometheus \
  --network host \
  -v /root/prometheus-lab/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.51.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle
```

Chờ 5 giây để Prometheus thực hiện lượt scrape đầu tiên, sau đó kiểm tra endpoint sức khỏe:

```bash
sleep 5
curl -s http://localhost:9090/-/healthy
```

---

### 3. Kiểm Tra Trạng Thái Targets Qua Prometheus API

Truy vấn danh sách các targets đang được Prometheus quản lý:

```bash
curl -s http://localhost:9090/api/v1/targets | \
  jq -r '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'
```

Tất cả 3 targets đều phải hiển thị trường **`"health": "up"`**.

Bạn cũng có thể thực thi truy vấn metric hệ thống tự sinh `up`:

```bash
curl -s "http://localhost:9090/api/v1/query?query=up" | \
  jq -r '.data.result[] | {job: .metric.job, status: .value[1]}'
```
*(Giá trị `1` nghĩa là mục tiêu đang hoạt động tốt và scrape thành công)*.

---

### 4. Yêu Cầu Hoàn Thành Bước 3

Nhấn **Check** để hệ thống tự động kiểm tra xem Prometheus đã thu thập thành công số liệu từ cả 3 nguồn (Prometheus, Node Exporter, Redis Exporter) hay chưa.
