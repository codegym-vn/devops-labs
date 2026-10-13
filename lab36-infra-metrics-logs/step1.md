# Bước 1: Triển Khai Node Exporter Thu Thập Metrics Máy Chủ

**Prometheus Node Exporter** là thành phần tiêu chuẩn công nghiệp được phát triển để thu thập toàn bộ các chỉ số phần cứng và thông số hoạt động của nhân hệ điều hành Linux (Hardware and OS Metrics). Node Exporter đọc trực tiếp các hệ thống tệp ảo **/proc** và **/sys**, bóc tách dữ liệu và expose dưới dạng OpenMetrics chuẩn qua giao thức HTTP trên cổng **9100**.

---

### 1. Khởi chạy Node Exporter Container

Chúng ta sẽ khởi chạy Node Exporter dưới dạng Docker container. Để thu thập chính xác các thông số của máy chủ gốc (Host), container cần được ánh xạ các thư mục **/proc**, **/sys** và gốc **/ (rootfs)** ở chế độ chỉ đọc (Read-Only), kèm theo chế độ mạng **--network host**:

```bash
cd /root/infra-monitoring-lab
docker run -d --name node-exporter --restart unless-stopped --network host -v "/proc:/host/proc:ro" -v "/sys:/host/sys:ro" -v "/:/rootfs:ro" prom/node-exporter:v1.8.0 --path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs
```{{exec}}

Kiểm tra trạng thái container Node Exporter:

```bash
docker ps --filter "name=node-exporter" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
```{{exec}}

---

### 2. Khảo sát dữ liệu Telemetry thô qua endpoint /metrics

Node Exporter mở sẵn endpoint **/metrics** trên cổng 9100. Truy vấn thử để xem định dạng dữ liệu:

```bash
curl -s http://localhost:9100/metrics | head -n 30
```{{exec}}

Mỗi dòng chỉ số gồm có tên metric, các nhãn định danh (Labels) và giá trị số thực tế tại thời điểm đo.

---

### 3. Phân tích các Collector hạ tầng quan trọng

Node Exporter cung cấp sẵn hàng chục bộ thu thập (Collectors). Hãy khảo sát 4 nhóm chỉ số sống còn của hạ tầng:

#### A. Chỉ số CPU (node_cpu_seconds_total)
Đo lường thời gian (tính bằng giây) mà từng nhân CPU đã tiêu tốn cho từng chế độ hoạt động (idle, user, system, iowait):

```bash
curl -s http://localhost:9100/metrics | grep -E '^node_cpu_seconds_total\{' | head -n 8
```{{exec}}

#### B. Chỉ số Bộ nhớ RAM (node_memory_*)
Cung cấp dung lượng bộ nhớ tổng (MemTotal), bộ nhớ còn trống hoàn toàn (MemFree) và bộ nhớ khả dụng thực tế (MemAvailable):

```bash
curl -s http://localhost:9100/metrics | grep -E '^node_memory_(MemTotal|MemAvailable|MemFree)_bytes'
```{{exec}}

#### C. Chỉ số Ổ đĩa & Tệp tin (node_disk_*)
Đo lường số lượng byte đã đọc và ghi vào từng phân vùng ổ đĩa:

```bash
curl -s http://localhost:9100/metrics | grep -E '^node_disk_(read|written)_bytes_total' | head -n 6
```{{exec}}

#### D. Chỉ số Mức tải hệ thống (node_load*)
Phản ánh tải trọng trung bình của CPU trong 1 phút, 5 phút và 15 phút (tương đương lệnh uptime):

```bash
curl -s http://localhost:9100/metrics | grep -E '^node_load[0-9]+'
```{{exec}}

---

### 4. Lưu trạng thái kiểm tra Node Exporter

Xuất thông số bộ nhớ của máy chủ vào tệp xác nhận:

```bash
curl -s http://localhost:9100/metrics | grep -E '^node_memory_MemTotal_bytes' > /root/infra-monitoring-lab/node-exporter-status.txt
cat /root/infra-monitoring-lab/node-exporter-status.txt
```{{exec}}

Nhấn **Check** để hoàn thành bước 1.
