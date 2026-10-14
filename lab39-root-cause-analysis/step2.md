# Bước 2: Cô Lập Điểm Nghẽn Bằng Distributed Tracing

Ở Bước 1, bạn đã xác định được triệu chứng: **Khách hàng gọi `/api/checkout` bị timeout sau hơn 2 giây**.

Nhưng trong kiến trúc Microservices gồm `Nginx Gateway ──► Order Service ──► Payment Service`:
- Có phải do Nginx bị nghẽn worker connection?
- Hay do Order Service bị quá tải CPU khi xử lý logic giỏ hàng?
- Hay do Payment Service gặp vấn đề ở tầng downstream?

Nếu không có Distributed Tracing, kỹ sư sẽ phải mở đồng thời 3 terminal để đọc log của 3 dịch vụ một cách mù quáng. Với OpenTelemetry và Jaeger đã được tích hợp sẵn, bạn có thể lập tức **cô lập chính xác nút thắt cổ chai (Pinpoint the Bottleneck)**.

---

### 1. Công Cụ Điều Tra: Jaeger Tracing Backend

Hệ thống đã triển khai sẵn **Jaeger All-in-One** tại cổng `16686`. Bạn có thể tương tác với Jaeger theo 2 cách:

#### Cách 1: Sử dụng Jaeger HTTP API qua Terminal (Khuyên dùng)
Truy vấn danh sách các traces của dịch vụ `order-service` với giới hạn 5 traces gần nhất:

```bash
curl -s "http://localhost:16686/api/traces?service=order-service&limit=5" | jq .
```

Để lọc nhanh các trace có độ trễ lớn (thời gian thực thi > 2 giây, tức > `2000000` microgiây) hoặc gắn cờ lỗi:

```bash
curl -s "http://localhost:16686/api/traces?service=order-service&limit=5" | \
  jq -r '.data[] | select(.spans[].duration > 2000000) | {traceID: .traceID, duration_ms: (.spans[0].duration / 1000)}'
```

#### Cách 2: Mở Jaeger Web UI
Nếu nền tảng hỗ trợ cổng Web Preview, bạn có thể mở cổng `16686` trên trình duyệt để quan sát biểu đồ Waterfall trực quan.

---

### 2. Thử Thách Phân Tích Cây Phân Cấp Span (Waterfall Hierarchy)

Khi kiểm tra một Trace bị trễ, bạn hãy giải phẫu cây phân cấp của nó:

```text
Trace: [==================================================] 2150ms (order_checkout)
  ├── call_payment_service [==============================] 2100ms
  │     └── payment_checkout [============================] 2095ms (payment-service)
  │           └── db_acquire_connection [=================] 2005ms (TIMEOUT / ERROR!)
```

Hãy tự trả lời 3 câu hỏi điều tra then chốt:
1. **Dịch vụ nào** đang chiếm hơn 90% tổng thời gian phản hồi của request? (`order-service` hay `payment-service`?)
2. **Tên Span con cụ thể nào** bị treo và ném ra trạng thái lỗi (`SpanStatusCode.ERROR`)?
3. **Mã Trace ID** (chuỗi 32 ký tự hex) của trace bị lỗi là gì? Hãy copy mã này để sử dụng làm chìa khóa liên kết sang bước điều tra Log.

> [!TIP]
> Bạn có thể trích xuất tự động mã `traceID` của một trace bị timeout bằng lệnh sau:
> ```bash
> curl -s "http://localhost:16686/api/traces?service=order-service&limit=10" | \
>   jq -r '.data[] | select(.spans[].operationName == "db_acquire_connection") | .traceID' | head -n 1
> ```

---

### 3. Yêu Cầu Hoàn Thành Bước 2

Sau khi xác định được dịch vụ và span gây nghẽn, hãy lưu bằng chứng vào tệp **/root/incident-report/step2-trace.txt**:

```bash
# Thay the <SAMPLE_TRACE_ID> bang trace ID thuc te ban trich xuat duoc tu Jaeger
cat << 'EOF' > /root/incident-report/step2-trace.txt
CULPRIT_SERVICE=payment-service
BOTTLENECK_SPAN=db_acquire_connection
SAMPLE_TRACE_ID=d29c8e417a810b42f10b7a9128ca0192
EOF
```

*(Lưu ý: Đảm bảo trường `SAMPLE_TRACE_ID` là một Trace ID thực tế có 32 ký tự hex từ hệ thống Jaeger).*

Nhấn **Check** để hệ thống kiểm tra tính chính xác của bằng chứng bạn vừa tìm được.
