# Bước 2: Tính Toán Hiệu Năng Hạ Tầng (CPU, RAM & Network)

Trong thực tế vận hành hạ tầng máy chủ Linux, các chỉ số phần cứng thô từ Node Exporter không thể dùng trực tiếp để đưa lên biểu đồ báo cáo mà cần được xử lý qua các công thức PromQL chuẩn mực.

---

### 1. Phân Biệt Xử Lý Dữ Liệu Giữa Counter Và Gauge

- **Với Gauge (Bộ nhớ RAM, Nhiệt độ, Disk Free):** Có thể thực hiện các phép toán số học cộng, trừ, nhân, chia (`+`, `-`, `*`, `/`) trực tiếp giữa các metrics.
- **Với Counter (CPU Seconds, Network Bytes, Disk I/O Operations):** Giá trị luôn tăng tích lũy từ lúc bật máy. Để biết *tốc độ biến thiên mỗi giây*, bắt buộc phải đưa vào Range Vector kết hợp cùng hàm **`rate()`**.

---

### 2. Công Thức Chuẩn SRE: Tính Phần Trăm (%) CPU Đang Sử Dụng

Metric `node_cpu_seconds_total` ghi nhận số giây CPU đã tiêu tốn phân loại theo từng chế độ (`mode="idle"`, `mode="user"`, `mode="system"`...).

Để tính phần trăm CPU mà máy chủ đang thực sự hoạt động, tư duy chuẩn là: **Lấy 100% trừ đi phần trăm thời gian CPU đang rảnh rỗi (idle)**:

```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)
```

Thực thi truy vấn qua terminal để xem kết quả % CPU tức thời:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)' | \
  jq -r '.data.result[] | "CPU USAGE: \(.value[1]) %"'
```

---

### 3. Công Thức Tính Phần Trăm (%) RAM Tiêu Thụ

Node Exporter cung cấp hai metric dạng Gauge:
- `node_memory_MemTotal_bytes`: Tổng dung lượng RAM vật lý.
- `node_memory_MemAvailable_bytes`: Dung lượng RAM còn khả dụng cho ứng dụng.

Công thức tính tỷ lệ phần trăm RAM đã bị chiếm dụng:

```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))' | \
  jq -r '.data.result[] | "RAM USED: \(.value[1]) %"'
```

---

### 4. Công Thức Tính Băng Thông Mạng (Network Throughput KB/s)

Đo lường tốc độ nhận dữ liệu qua card mạng thực tế (loại trừ loopback `lo` và card ảo `veth`):

```promql
sum(rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[2m])) / 1024
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[2m])) / 1024' | \
  jq -r '.data.result[] | "NETWORK INBOUND: \(.value[1]) KB/s"'
```

---

### 5. Yêu Cầu Hoàn Thành Bước 2

Hãy lưu công thức tính **phần trăm sử dụng CPU toàn máy chủ** vào tệp **/root/promql-lab/step2-cpu-query.txt**:

```bash
echo '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)' > /root/promql-lab/step2-cpu-query.txt
cat /root/promql-lab/step2-cpu-query.txt
```

*(Lưu ý: Bạn cũng có thể dùng cú pháp có `by (instance)` hoặc `without (cpu)` tùy ý, miễn là trả về đúng giá trị % CPU hoạt động).*

Sau khi hoàn tất, nhấn **Check** để hệ thống kiểm tra công thức tính CPU của bạn.
