# Bước 1: Triển Khai Node Exporter & Khảo Sát Định Dạng OpenMetrics

**Node Exporter** là Exporter phổ biến nhất trong hệ sinh thái Prometheus, được thiết kế để thu thập toàn bộ các chỉ số phần cứng và hạt nhân Linux (CPU, Memory, Disk I/O, File System, Network).

---

### 1. Khởi Chạy Node Exporter Bằng Docker

Khởi chạy container **node-exporter** với quyền truy cập vào thông tin hệ thống của máy host:

```bash
docker run -d --name node-exporter \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.0 \
  --path.rootfs=/host
```

Kiểm tra trạng thái container và xác nhận cổng `9100` đã mở:

```bash
docker ps --filter "name=node-exporter"
curl -s -I http://localhost:9100/metrics | head -n 5
```

---

### 2. Giải Phẫu Cấu Trúc Bản Ghi Chuẩn OpenMetrics

Gửi HTTP GET request đến endpoint `/metrics` để xem dữ liệu thô:

```bash
curl -s http://localhost:9100/metrics | grep -A 3 "^# HELP node_cpu_seconds_total"
```

Một khối metric tiêu chuẩn luôn bao gồm 3 phần:
1. **Dòng `# HELP`**: Mô tả ý nghĩa của chỉ số (Ví dụ: *Seconds the CPUs spent in each mode*).
2. **Dòng `# TYPE`**: Khai báo kiểu dữ liệu:
   - **`counter`**: Giá trị chỉ có thể tăng lên theo thời gian hoặc reset về 0 khi khởi động lại máy (Ví dụ: `node_cpu_seconds_total`, số bytes truyền nhận qua mạng).
   - **`gauge`**: Giá trị có thể tăng hoặc giảm tự do tại bất kỳ thời điểm nào (Ví dụ: `node_memory_MemAvailable_bytes` - dung lượng RAM trống).
3. **Dòng dữ liệu (Samples)**: Tên metric đi kèm cặp nhãn nhúng (Labels) trong dấu ngoặc nhọn `{...}` và giá trị float:
   ```text
   node_cpu_seconds_total{cpu="0",mode="idle"} 12450.32
   node_cpu_seconds_total{cpu="0",mode="system"} 312.45
   ```

---

### 3. Yêu Cầu Hoàn Thành Bước 1

Hãy trích xuất 5 dòng mẫu chứa cả metric dạng `counter` (`node_cpu_seconds_total`) và dạng `gauge` (`node_memory_MemAvailable_bytes`) lưu vào tệp **/root/prometheus-lab/step1-metrics.txt**:

```bash
curl -s http://localhost:9100/metrics | grep -E "^node_cpu_seconds_total|^node_memory_MemAvailable_bytes" | head -n 5 > /root/prometheus-lab/step1-metrics.txt
cat /root/prometheus-lab/step1-metrics.txt
```

Sau khi hoàn tất, hãy nhấn **Check** để hệ thống kiểm tra trạng thái hoạt động của Node Exporter.
