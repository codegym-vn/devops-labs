# Bước 1: Khảo Sát Kiến Trúc Tương Quan & Khởi Chạy Observability

Trước khi tiến hành bơm tải, bạn cần kiểm tra toàn bộ chuỗi mắt xích giám sát để chắc chắn rằng: khi có bất kỳ request nào được gửi đến, các chỉ số tại server sẽ được Prometheus thu thập và hiển thị ngay lập tức lên Grafana.

---

### 1. Kiểm Tra Ứng Dụng Mục Tiêu & Endpoint Metrics

Kiểm tra trạng thái hoạt động của dịch vụ Ecommerce:

```bash
curl -s http://localhost:8080/health | jq .
```

*Kết quả:*
```json
{
  "status": "UP"
}
```

Kiểm tra cổng dữ liệu giám sát `/metrics` theo chuẩn định dạng của Prometheus:

```bash
curl -s http://localhost:8080/metrics | grep -E "(http_requests_total|app_active_connections|app_cpu_usage_percent)"
```

Bạn sẽ thấy các metric đo lường:
- `http_requests_total`: Số lượng request đã phục vụ theo mã trạng thái HTTP.
- `app_active_connections`: Số kết nối người dùng đang hoạt động đồng thời.
- `app_cpu_usage_percent`: Mức tiêu hao CPU tương ứng của máy chủ.

---

### 2. Xác Nhận Prometheus Đang Thu Thập Dữ Liệu Mỗi 2 Giây

Trong môi trường kiểm thử tải, chu kỳ scrape thông thường (15s hoặc 1m) là quá chậm để bắt trọn các đợt tăng tải đột biến (Spikes). Prometheus trong bài lab này được cấu hình chu kỳ cào siêu nhanh: **`scrape_interval: 2s`**.

Kiểm tra trạng thái kết nối của Prometheus tới ứng dụng:

```bash
curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | {job: .labels.job, health: .health, lastScrape: .lastScrape}'
```

*Đảm bảo rằng target `target-api` đang ở trạng thái `"health": "up"`.*

---

### 3. Khảo Sát Dashboard Trên Grafana

Hệ thống Grafana đã được nạp sẵn Dashboard **"Load Testing & System Saturation Correlation"**:
- Truy cập Grafana tại địa chỉ: `http://localhost:3000` (hoặc mở cổng 3000 trên giao diện Killercoda).
- Bạn không cần đăng nhập vì chế độ Anonymous Admin đã được kích hoạt.
- Mở menu **Dashboards** -> chọn **Load Testing & System Saturation Correlation**.

Dashboard gồm 5 Panel trực quan:
1. **Active Client Connections:** Số kết nối đồng thời từ k6.
2. **Server CPU Saturation:** Thước đo phần trăm (%) CPU với cảnh báo màu Đỏ khi vượt 85%.
3. **Throughput (RPS):** Tốc độ request mỗi giây theo từng API endpoint.
4. **Average Response Latency (ms):** Thời gian phản hồi trung bình của server.
5. **HTTP Error Rate (%) & Saturation Incidents:** Đồ thị theo dõi lỗi 5xx và biến cố cạn kiệt thread pool.

---

### 4. Chạy Thử Kiểm Tra Tính Thông Suốt (Quick Check)

Chạy thử 1 request k6 nhanh để kích hoạt dòng dữ liệu đầu tiên:

```bash
k6 run --vus 2 --duration 3s /root/load-monitoring-lab/scripts/load-baseline.js
```

Sau khi hoàn tất, nhấn **Check** để hệ thống xác nhận toàn bộ hạ tầng Observability đã sẵn sàng cho bước tạo tải!
