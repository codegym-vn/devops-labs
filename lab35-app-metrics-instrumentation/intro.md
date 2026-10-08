# Lab 35: Instrument Ứng Dụng Để Thu Thập Metrics

Trong ba trụ cột của Observability (Metrics, Logs, Traces), **Metrics** đóng vai trò là "hệ thống cảnh báo sớm" (Early Warning System) quan trọng nhất. Metrics cung cấp các chỉ số định lượng dạng chuỗi thời gian (Time-series data) về trạng thái sức khỏe, lưu lượng truy cập, tỷ lệ lỗi và độ trễ phản hồi của hệ thống.

Một sai lầm phổ biến của các kỹ sư mới bắt đầu là chỉ giám sát máy chủ ở tầng hạ tầng (CPU, RAM). Khi ứng dụng bị nghẽn luồng xử lý hoặc trả về hàng nghìn lỗi HTTP 500, CPU máy chủ có thể vẫn ở mức thấp, khiến hệ thống giám sát hạ tầng hoàn toàn "mù" trước sự cố. Để giải quyết vấn đề này, chúng ta cần thực hiện **Application Instrumentation (Gắn cảm biến đo lường vào mã nguồn)**.

---

## 1. Kiến Trúc Thu Thập Metrics Của Prometheus

```
┌──────────────────────────────────────┐                ┌──────────────────────────────┐
│          NODE.JS APPLICATION         │                │      PROMETHEUS SERVER       │
├──────────────────────────────────────┤                ├──────────────────────────────┤
│ • Express API Service                │   HTTP GET     │ • Pull-based Architecture    │
│ • prom-client library                │  /metrics      │ • Scrape interval: 5s        │
│ • Counter: http_requests_total       │◄───────────────┤ • Time-series Database (TSDB)│
│ • Histogram: request_duration_seconds│ (OpenMetrics)  │ • PromQL Engine              │
│ • Gauge: active_requests             │                │ • Web UI (Port 9090)         │
└──────────────────────────────────────┘                └──────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Khởi tạo dịch vụ và kích hoạt thu thập chỉ số runtime:** Tích hợp thư viện `prom-client` và kích hoạt bộ thu thập chỉ số mặc định của tiến trình Node.js (CPU, Heap Memory, Event Loop).
2. **Xây dựng Custom Metrics đo lường chuyên sâu:** Tự thiết kế và cài đặt ba loại metric cốt lõi gồm Counter đếm request, Histogram đo độ trễ p95 và Gauge đo số kết nối đồng thời.
3. **Triển khai Prometheus Server:** Cấu hình và khởi chạy Prometheus ở chế độ thu thập tự động (Scrape Job) kết nối với ứng dụng.
4. **Phân tích hiệu năng bằng PromQL:** Sinh tải lưu lượng đa dạng (thành công, lỗi 500) và viết các câu lệnh truy vấn PromQL tính toán thông lượng RPS, tỷ lệ lỗi và độ trễ phản hồi.

Nhấn **Next** để bắt đầu bước đầu tiên!
