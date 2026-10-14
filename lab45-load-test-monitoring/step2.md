# Bước 2: Thực Thi Tải Nền & Quan Sát Thời Gian Thực Trên Grafana

Trong bước này, bạn sẽ cho k6 chạy tải ổn định ở mức trung bình (20 VUs) trong vòng 45 giây dưới nền (Background process) và quan sát sự phản ánh tức thời của các đồ thị trên Grafana Dashboard.

---

### 1. Khởi Chạy Kịch Bản Tải Nền (Baseline Load)

Khởi chạy k6 trong chế độ chạy ngầm để giải phóng terminal cho việc theo dõi:

```bash
nohup k6 run --vus 20 --duration 45s /root/load-monitoring-lab/scripts/load-baseline.js > /root/load-monitoring-lab/reports/baseline-run.log 2>&1 &
```

Kiểm tra xem tiến trình k6 đã chạy thành công chưa:

```bash
ps aux | grep k6
```

---

### 2. Quan Sát Trực Quan Trên Grafana Dashboard

Mở tab trình duyệt chứa Grafana Dashboard (`http://localhost:3000/d/load-correlation`):
- Đặt chế độ tự động làm mới (**Auto-refresh**) ở góc trên bên phải thành **2s** và khung thời gian hiển thị là **Last 5 minutes**.
- **Hiện tượng quan sát được ở mức tải bình thường:**
  1. **Active Client Connections:** Nhảy từ 0 lên xấp xỉ 20 kết nối.
  2. **Throughput (RPS):** Đường biểu đồ tăng vọt từ 0 lên ~60 - 80 requests/giây cho cả hai endpoint `/api/products` và `/api/orders`.
  3. **Server CPU Saturation:** Kim đồng hồ Gauge dao động an toàn trong vùng **Xanh lá** (khoảng 25% - 35%).
  4. **Average Response Latency:** Duy trì rất thấp và ổn định (khoảng 20ms - 35ms).
  5. **HTTP Error Rate:** Đường biểu đồ nằm phẳng ở mức `0%`.

---

### 3. Kiểm Chứng Trực Tiếp Bằng Truy Vấn PromQL Từ Terminal

Trong khi tải đang chạy, bạn cũng có thể thực thi nhanh các câu truy vấn PromQL qua API của Prometheus để xác nhận số liệu:

```bash
# 1. Truy vấn Throughput tức thời (RPS)
curl -s 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total%5B10s%5D))' | jq -r '.data.result[0].value[1]'

# 2. Truy vấn mức tiêu hao CPU hiện tại (%)
curl -s 'http://localhost:9090/api/v1/query?query=app_cpu_usage_percent' | jq -r '.data.result[0].value[1]'
```

---

### 4. Ghi Lại Ảnh Chụp Trạng Thái Baseline

Chờ tiến trình k6 hoàn thành (khoảng 45 giây sau khi khởi chạy), sau đó xuất báo cáo trạng thái Baseline vào `/root/load-monitoring-lab/reports/step2-baseline-state.json`:

```bash
cat << 'EOF' > /root/load-monitoring-lab/reports/step2-baseline-state.json
{
  "test_phase": "BASELINE_MONITORING",
  "concurrency_vus": 20,
  "system_state": {
    "cpu_zone": "GREEN",
    "avg_latency_ms": "<50ms",
    "error_rate_percent": 0
  },
  "status": "COMPLETED"
}
EOF
cat /root/load-monitoring-lab/reports/step2-baseline-state.json
```

Sau khi hoàn thành, nhấn **Check** để hoàn thành Bước 2!
