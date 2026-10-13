# Bước 2: Cấu Hình Prometheus Scrape & Phân Tích Bằng PromQL

Sau khi Node Exporter đã mở endpoint **/metrics**, bước tiếp theo là cấu hình **Prometheus Server** để tự động kéo số liệu định kỳ và thực thi các câu truy vấn PromQL phân tích hiệu năng phần cứng.

---

### 1. Tạo tệp cấu hình prometheus.yml

Khởi tạo tệp cấu hình Prometheus với chu kỳ kéo (scrape interval) là 5 giây và khai báo mục tiêu thu thập là **node-exporter** trên cổng 9100:

```bash
cd /root/infra-monitoring-lab
cat << 'EOF' > prometheus.yml
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          environment: 'production'
          node_role: 'compute-node'
EOF
cat prometheus.yml
```{{exec}}

---

### 2. Khởi chạy Prometheus Server

Chạy container Prometheus chính thức với chế độ mạng **--network host** và gắn tệp cấu hình vừa tạo:

```bash
docker rm -f prometheus 2>/dev/null || true
docker run -d --name prometheus --network host -v /root/infra-monitoring-lab/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest
```{{exec}}

Kiểm tra container đang chạy:

```bash
docker ps --filter "name=prometheus" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```{{exec}}

---

### 3. Kiểm tra trạng thái kết nối Scrape Target

Chờ 5 giây để Prometheus hoàn tất chu kỳ thu thập đầu tiên, sau đó thẩm tra trạng thái Target qua API của Prometheus:

```bash
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health, environment: .labels.environment}'
```{{exec}}

Trường **health: "up"** xác nhận Prometheus đã kết nối thành công tới Node Exporter và đang nạp dữ liệu vào cơ sở dữ liệu chuỗi thời gian (TSDB).

---

### 4. Thực thi các truy vấn PromQL hạ tầng cốt lõi

Hãy thực thi 4 câu truy vấn PromQL tiêu chuẩn ngành để phân tích tài nguyên máy chủ:

#### A. Tính toán Tỷ lệ % CPU đang sử dụng
Node Exporter ghi nhận thời gian CPU tiêu tốn cho từng chế độ. Ta tính tốc độ tăng của chế độ rảnh rỗi (idle), sau đó lấy 100% trừ đi để ra tổng tỷ lệ CPU đang tiêu thụ:

```bash
curl -s -G --data-urlencode 'query=100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "CPU Usage %", usage: .value[1]}'
```{{exec}}

#### B. Tính toán Tỷ lệ % Bộ nhớ RAM đang sử dụng
Lấy tỷ lệ RAM khả dụng thực tế so với tổng RAM, sau đó trừ đi từ 1 và nhân 100:

```bash
curl -s -G --data-urlencode 'query=(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "Memory Usage %", usage: .value[1]}'
```{{exec}}

#### C. Đo lường Tải hệ thống tức thời (System Load 1m)

```bash
curl -s -G --data-urlencode 'query=node_load1' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "Load Average (1m)", load: .value[1]}'
```{{exec}}

#### D. Đo lường Tốc độ ghi ổ đĩa (Disk Write Throughput - Bytes/sec)

```bash
curl -s -G --data-urlencode 'query=sum(rate(node_disk_written_bytes_total[1m]))' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "Disk Write Bps", bytes_per_sec: .value[1]}'
```{{exec}}

---

### 5. Xuất kết quả PromQL ra tệp kiểm tra

Lưu kết quả truy vấn tỷ lệ CPU ra tệp **infra-promql.json**:

```bash
curl -s -G --data-urlencode 'query=100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)' http://localhost:9090/api/v1/query > /root/infra-monitoring-lab/infra-promql.json
cat /root/infra-monitoring-lab/infra-promql.json | jq .
```{{exec}}

Nhấn **Check** để hoàn thành bước 2.
