### 1.1. Tìm hiểu kiến trúc Distributed Tracing và Chuẩn W3C Trace Context

Trong hệ thống phân tán, một **Trace** đại diện cho toàn bộ hành trình của một request khi đi qua chuỗi các dịch vụ. Mỗi đơn vị công việc (một hàm xử lý, một câu query CSDL, một lời gọi HTTP) được đóng gói thành một **Span**.

Một Span chứa các thông tin then chốt:
- **Trace ID**: Chuỗi hexa 32 ký tự (128-bit) dùng chung cho tất cả các Span thuộc cùng một request.
- **Span ID**: Chuỗi hexa 16 ký tự (64-bit) định danh duy nhất cho từng thao tác cụ thể.
- **Parent Span ID**: Mã Span của công đoạn cha đã gọi ra công đoạn này (đối với Root Span, trường này rỗng).
- **Span Attributes (Tags)**: Siêu dữ liệu mô tả ngữ cảnh (ví dụ: **http.method**, **http.status_code**, **order.id**).
- **Span Events (Logs)**: Dấu mốc thời gian kèm thông điệp nội bộ (ví dụ: **cache_miss**, **validation_passed**).

Để truyền ngữ cảnh giữa các máy chủ khác nhau qua mạng, tổ chức W3C đưa ra chuẩn **W3C Trace Context** sử dụng HTTP header **traceparent** với cấu trúc:
**version-trace_id-parent_id-trace_flags** (Ví dụ: **00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01**).

---

### 1.2. Triển khai Jaeger All-in-One Container

Chúng ta sẽ sử dụng **Jaeger All-in-One** làm cụm xử lý và lưu trữ dữ liệu Trace tập trung. Jaeger hỗ trợ tiếp nhận dữ liệu đo lường trực tiếp qua giao thức mở **OTLP (OpenTelemetry Protocol)**.

Chạy lệnh sau để khởi động container Jaeger:

```bash
docker rm -f jaeger 2>/dev/null || true
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:1.53
```{{exec}}

Giải thích các cổng mạng được mở:
- **16686**: Giao diện người dùng đồ họa (Jaeger Web UI) và REST API.
- **4318**: Điểm tiếp nhận dữ liệu OTLP qua giao thức HTTP (OpenTelemetry HTTP Exporter endpoint).
- **4317**: Điểm tiếp nhận dữ liệu OTLP qua giao thức gRPC.

---

### 1.3. Kiểm tra trạng thái hoạt động của Jaeger

Xác minh container Jaeger đã khởi động ổn định và sẵn sàng tiếp nhận kết nối:

```bash
docker ps --filter "name=jaeger" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```{{exec}}

Kiểm tra API danh sách dịch vụ của Jaeger:

```bash
curl -s http://localhost:16686/api/services | jq .
```{{exec}}

Đầu ra trả về cấu trúc JSON hiển thị dịch vụ nội bộ **jaeger-query**:

```json
{
  "data": [
    "jaeger-query"
  ],
  "total": 1,
  "limit": 0,
  "offset": 0,
  "errors": null
}
```

Bạn có thể mở giao diện quản trị Jaeger bằng cách nhấp vào liên kết sau (mở sang tab mới):
<a href="{{TRAFFIC_HOST1_16686}}" target="_blank">Mở Jaeger UI (Cổng 16686)</a>

Hoặc trên thanh công cụ terminal Killercoda, bấm vào dấu **+** -> Chọn **Select Port to View on Host 1** -> Nhập **16686** và nhấn **Open Port**.

Bấm **Check** để hoàn thành bước 1.
