# Bước 4: Phân Tích Tương Quan Chỉ Số & Lập Báo Cáo Capacity Planning

Sau khi hoàn thành thử nghiệm và xác định được điểm gãy, nhiệm vụ cuối cùng của kỹ sư SRE là tổng hợp dữ liệu từ cả hai phía (**Client k6** và **Server Prometheus**) để lập **Báo cáo hoạch định năng lực (Capacity Planning & Performance Report)** nhằm tư vấn cho đội ngũ phát triển và quản lý hạ tầng.

---

### 1. Bảng Đối Chiếu Tương Quan Giữa Client & Server

Từ dữ liệu quan sát được trên Grafana và k6, chúng ta phân loại hành vi của hệ thống thành 3 vùng tải:

| Vùng tải | Mức người dùng ảo (VUs) | Tải CPU Server | Độ trễ p95 Latency | Tỷ lệ lỗi 5xx | Đánh giá SRE |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Vùng An Toàn (Green)** | Dưới 40 VUs | < 65% | < 60ms | 0% | Vận hành lý tưởng, đáp ứng 100% cam kết SLA |
| **Vùng Cảnh Báo (Yellow)** | 40 - 65 VUs | 65% - 85% | 80ms - 200ms | < 1% | Tiệm cận ngưỡng bão hòa, cần kích hoạt Auto-scaling |
| **Vùng Điểm Gãy (Red)** | Trên 70 VUs | > 85% | > 400ms - 800ms | > 5% - 15% | Bão hòa Worker Thread Pool, dịch vụ sụt giảm nghiêm trọng |

---

### 2. Khuyến Nghị Kỹ Thuật (Remediation & Action Items)

Để hệ thống có thể mở rộng (scale) an toàn vượt qua mốc 70 VUs, kỹ sư SRE đề xuất 3 giải pháp kiến trúc:

1. **Thiết lập Horizontal Pod Autoscaler (HPA):**
   - Đặt ngưỡng kích hoạt tự động nhân bản (Scale-out) container khi mức sử dụng CPU đạt **70%** (trước khi bước vào vùng Đỏ).
2. **Chuyển đổi kiến trúc xử lý đơn hàng sang Bất đồng bộ (Async Queue):**
   - Thay vì xử lý đồng bộ trực tiếp tại `POST /api/orders`, đưa thông tin đơn hàng vào hàng đợi (Redis Queue, RabbitMQ hoặc Apache Kafka) để bảo vệ thread pool của API Gateway.
3. **Cấu hình Rate Limiting tại tầng Nginx / Ingress:**
   - Giới hạn tối đa 100 requests/giây cho mỗi client IP để phòng chống tấn công DoS hoặc kịch bản tải đột biến làm tê liệt toàn bộ hạ tầng.

---

### 3. Tạo Tệp Báo Cáo Nghiệm Thu Hoạch Định Năng Lực

Khởi tạo tệp báo cáo tổng kết chính thức tại `/root/load-monitoring-lab/reports/capacity-planning-report.json`:

```bash
cat << 'EOF' > /root/load-monitoring-lab/reports/capacity-planning-report.json
{
  "project": "ECOMMERCE-PLATFORM-PERFORMANCE-AUDIT",
  "methodology": "CORRELATION_TESTING_K6_PROMETHEUS",
  "capacity_boundaries": {
    "safe_operating_capacity_vus": 40,
    "warning_threshold_vus": 65,
    "breaking_point_vus": 70,
    "max_sustainable_rps": 120
  },
  "bottleneck_root_cause": {
    "subsystem": "Worker Thread Pool & CPU Saturation",
    "primary_factor": "Synchronous order processing holding worker threads under heavy concurrency",
    "secondary_factor": "CPU utilization exceeded 85% leading to queue starvation and 503 errors"
  },
  "architectural_recommendations": [
    "Configure HPA target at 70% CPU utilization",
    "Decouple POST /api/orders with asynchronous message queue (Redis/RabbitMQ)",
    "Implement rate limiting at Ingress Gateway"
  ],
  "verified_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
cat /root/load-monitoring-lab/reports/capacity-planning-report.json | jq .
```

Sau khi hoàn tất việc tạo báo cáo, nhấn **Check** để hệ thống đánh giá và hoàn thành toàn bộ bài Lab 45!
