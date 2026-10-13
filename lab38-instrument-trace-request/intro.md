Trong các hệ thống phân tán và kiến trúc vi dịch vụ (Microservices), một yêu cầu từ người dùng (User Request) thường phải đi qua hàng loạt tầng dịch vụ độc lập: API Gateway, Order Service, Payment Service, Inventory Service và các hệ thống cơ sở dữ liệu. Khi hệ thống gặp độ trễ cao (Latency Spikes) hoặc phát sinh mã lỗi 500/502, các giải pháp giám sát truyền thống dựa trên Metrics và Log rời rạc không thể cung cấp bức tranh toàn cảnh về hành trình của request xuyên suốt ranh giới mạng (Network Boundary).

**Distributed Tracing** (Truy vết phân tán) ra đời như trụ cột thứ ba của Observability, cho phép gắn thẻ từng request bằng một mã định danh duy nhất (**Trace ID**) và ghi nhận chi tiết thời gian thực thi của từng công đoạn (**Spans**).

### Mục tiêu bài học:
1. **Nắm vững mô hình dữ liệu OpenTelemetry**: Hiểu sâu cơ chế hoạt động của Trace, Span, Span Context và chuẩn truyền ngữ cảnh **W3C Trace Context (traceparent)**.
2. **Instrument ứng dụng và lan truyền Context**: Khởi tạo OpenTelemetry SDK để thu thập In-Process Spans và thực hiện Context Propagation qua HTTP giữa các microservices.
3. **Phân tích hiệu năng và truy vết sự cố**: Trực quan hóa hành trình request dạng biểu đồ Gantt (Waterfall) trên Jaeger UI để xác định chính xác nút thắt cổ chai và nguyên nhân gốc rễ gây lỗi.

Bấm **Start** để bắt đầu bài thực hành!
