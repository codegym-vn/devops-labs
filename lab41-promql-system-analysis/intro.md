# Lab 41: Phân Tích Hệ Thống Bằng PromQL

Trong hệ thống giám sát hiện đại, việc thu thập dữ liệu (Metrics Collection) mới chỉ là 50% chặng đường. 50% còn lại quyết định sự thành bại của một kỹ sư SRE / DevOps là năng lực khai thác và trích xuất thông tin chi tiết từ dữ liệu chuỗi thời gian (Time-series Data) thông qua **PromQL (Prometheus Query Language)**.

PromQL được thiết kế đặc thù cho mô hình dữ liệu đa chiều (Multi-dimensional Data Model). Không giống như SQL làm việc trên các bảng tĩnh, PromQL xử lý các luồng dữ liệu biến thiên theo thời gian thực để trả lời những câu hỏi sống còn:
- *Máy chủ hiện đang chạy bao nhiêu % CPU? Còn bao nhiêu % RAM?*
- *Hệ thống đang phục vụ bao nhiêu yêu cầu mỗi giây (RPS)?*
- *Tỷ lệ lỗi 5xx là bao nhiêu %? Có vi phạm cam kết SLA/SLO hay không?*
- *Độ trễ phản hồi của 95% khách hàng (p95 latency) đang ở mức bao nhiêu mili-giây?*

---

## 1. Kiến Trúc Môi Trường Thực Hành

Hệ thống đã chuẩn bị sẵn một cụm môi trường hoàn chỉnh đang hoạt động:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      TRAFFIC GENERATOR (DAEMON)                        │
 │ • Tự động gửi liên tục các request GET/POST vào hệ thống theo chu kỳ   │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌───────────────────────────────────┴────────────────────────────────────┐
 │  ECOMMERCE BACKEND API (:8080)    │  HOST OS & HARDWARE (:9100)        │
 │  • /api/products, /api/orders     │  • CPU, Memory, Disk, Network      │
 │  • Counter: http_requests_total   │  • Metric: node_cpu_seconds_total  │
 │  • Histogram: request_duration    │  • Metric: node_memory_*           │
 └─────────────────┬─────────────────┴──────────────────┬─────────────────┘
                   │                                    │
                   └─────────────────┬──────────────────┘
                                     │ HTTP Scrape (2s)
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                  PROMETHEUS TSDB SERVER (PORT 9090)                    │
 │ • Lưu trữ các chuỗi thời gian phân tách theo bộ nhãn (Labels)          │
 │ • Cung cấp động cơ PromQL Engine xử lý truy vấn tức thời & phạm vi     │
 └────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Làm chủ bộ lọc nhãn (Label Selectors & Matchers):** Phân biệt Instant Vector và Range Vector; sử dụng thành thạo Regular Expressions trong PromQL.
2. **Tính toán hiệu năng máy chủ (Infrastructure Metrics):** Nắm vững công thức kinh điển tính % CPU Usage thực tế từ metric Counter và % RAM tiêu thụ từ metric Gauge.
3. **Phân tích chất lượng ứng dụng theo phương pháp RED:** Đo lường Rate (RPS), Error Rate (%) và tính toán độ trễ bách phân vị (p95/p99 Percentile) bằng hàm `histogram_quantile`.
4. **Thiết lập biểu thức cảnh báo (Alert Expressions) & Xếp hạng Topk:** Sử dụng toán tử logic so sánh điều kiện vi phạm ngưỡng và hàm `topk` để tìm ra các endpoint tiêu tốn tài nguyên nhất.

Bấm **Start** để bước vào bài thực hành!
