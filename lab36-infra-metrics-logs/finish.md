# Chúc Mừng Bạn Đã Hoàn Thành Lab 36!

Bạn đã xuất sắc làm chủ bài thực hành **Thu Thập Metrics Và Logs Từ Hạ Tầng (Infrastructure Observability)**.

---

### Những Năng Lực Cốt Lõi Bạn Đã Làm Chủ:

1. **Thu thập chỉ số phần cứng với Prometheus Node Exporter:** Vận hành Exporter kết nối an toàn với nhân Linux để khai thác các thông số sống còn của CPU, RAM, Disk I/O và Network.
2. **Làm chủ kỹ thuật phân tích PromQL hạ tầng:** Xây dựng công thức tính toán tỷ lệ % CPU sử dụng từ idle counter, tỷ lệ sử dụng RAM thực tế, tải hệ thống tức thời và thông lượng I/O ổ đĩa.
3. **Quản trị nhật ký tập trung với Grafana Loki & Promtail:** Nắm vững triết lý thiết kế Index Labels siêu nhẹ của Loki, cấu hình Promtail Shipper theo dõi và đồng bộ log hệ thống thời gian thực.
4. **Điều tra sự cố chuyên sâu bằng LogQL:** Vận dụng thành thạo Stream Selector, bộ lọc từ khóa, biểu thức chính quy (Regex) và kỹ thuật Log-to-Metrics để đếm tần suất lỗi phục vụ cảnh báo tự động.

---

### Bảng Tra Cứu Nhanh (Cheat Sheet)

| Tác Vụ | Công Cụ | Cú Pháp / Lệnh Mẫu |
|---|---|---|
| **CPU Usage %** | PromQL | 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) |
| **Memory Usage %** | PromQL | (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 |
| **Disk Write Rate** | PromQL | sum(rate(node_disk_written_bytes_total[1m])) |
| **System Load 1m** | PromQL | node_load1 |
| **Lọc Log theo Nhãn** | LogQL | {job="infrastructure", env="production"} |
| **Lọc Log theo Từ Khóa** | LogQL | {job="infrastructure"} \|= "CRITICAL" |
| **Lọc Log theo Regex** | LogQL | {job="infrastructure"} \|~ "(Failed password\|Out of memory)" |
| **Log-to-Metrics (Đếm lỗi)** | LogQL | count_over_time({job="infrastructure"} \|= "ERROR" [1h]) |

---

Hạ tầng và ứng dụng của bạn giờ đây đã có đầy đủ khả năng quan sát hai chiều từ số liệu định lượng (Metrics) cho đến nhật ký chi tiết (Logs).
