### 2.1. Thiết lập Module Khởi Tạo OpenTelemetry Tracing

Trong thư mục làm việc **/root/tracing-lab**, chúng ta sẽ tạo tệp **tracer.js** đóng vai trò khởi tạo OpenTelemetry Node SDK, cấu hình **OTLPTraceExporter** để đẩy dữ liệu đo lường trực tiếp về cổng **4318** của Jaeger.

Chạy lệnh sau để tạo tệp **tracer.js**:

```bash
cat << 'EOF' > /root/tracing-lab/tracer.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { trace, context, propagation, SpanStatusCode } = require('@opentelemetry/api');

function initTracer(serviceName) {
  const exporter = new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces'
  });

  const sdk = new NodeSDK({
    serviceName: serviceName,
    traceExporter: exporter
  });

  sdk.start();

  return {
    tracer: trace.getTracer(serviceName),
    sdk: sdk
  };
}

module.exports = {
  initTracer,
  trace,
  context,
  propagation,
  SpanStatusCode
};
EOF
```{{exec}}

Giải thích các thành phần:
- **NodeSDK**: Lớp quản lý vòng đời của bộ công cụ OpenTelemetry trên môi trường Node.js.
- **OTLPTraceExporter**: Bộ xuất dữ liệu gửi các Span đã hoàn tất (ended spans) đến endpoint OTLP HTTP của Jaeger qua địa chỉ **http://localhost:4318/v1/traces**.
- **trace.getTracer(serviceName)**: Đối tượng chịu trách nhiệm sinh mã định danh và khởi tạo các Span với nhãn định danh dịch vụ tương ứng.

---

### 2.2. Xây dựng dịch vụ Order Service với In-Process Spans

Bây giờ, chúng ta sẽ xây dựng ứng dụng **order-service.js** lắng nghe trên cổng **3000**. Khi nhận một yêu cầu tạo đơn hàng (**POST /api/orders**), ứng dụng sẽ thực hiện:
1. Tạo một **Root Span** bao bọc toàn bộ chu kỳ sống của request.
2. Gắn các thuộc tính ngữ cảnh (**Span Attributes**) như **customer.id**, **order.amount**, **http.method**.
3. Tạo **Child Span 1** mang tên **validate_payload** để kiểm tra dữ liệu đầu vào và ghi lại mốc sự kiện (**Span Event**).
4. Tạo **Child Span 2** mang tên **database_save_order** để mô phỏng thời gian thực thi của câu lệnh ghi cơ sở dữ liệu.

Chạy lệnh sau để tạo **order-service.js**:

```bash
cat << 'EOF' > /root/tracing-lab/order-service.js
const express = require('express');
const { initTracer, trace, context, SpanStatusCode } = require('./tracer');

const { tracer } = initTracer('order-service');
const app = express();
app.use(express.json());

// Endpoint kiem tra trang thai dich vu
app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-service' });
});

// Endpoint tao don hang voi In-Process Spans
app.post('/api/orders', async (req, res) => {
  const { customerId, items, totalAmount } = req.body;
  
  // 1. Khoi tao Root Span cho HTTP Request
  const rootSpan = tracer.startSpan('POST /api/orders');
  rootSpan.setAttribute('http.method', 'POST');
  rootSpan.setAttribute('http.route', '/api/orders');
  rootSpan.setAttribute('customer.id', customerId || 'anonymous');
  rootSpan.setAttribute('order.amount', totalAmount || 0);

  const activeCtx = trace.setSpan(context.active(), rootSpan);

  try {
    // 2. Tao Child Span 1: Kiem tra hop le du lieu dau vao
    const valSpan = tracer.startSpan('validate_payload', {}, activeCtx);
    if (!items || items.length === 0) {
      valSpan.setStatus({ code: SpanStatusCode.ERROR, message: 'Danh sach san pham trong' });
      valSpan.end();
      rootSpan.setStatus({ code: SpanStatusCode.ERROR, message: 'Invalid payload' });
      rootSpan.end();
      return res.status(400).json({ error: 'Danh sach mat hang khong duoc de trong' });
    }
    // Ghi nhan Span Event
    valSpan.addEvent('validation_success', { items_count: items.length });
    valSpan.end();

    // 3. Tao Child Span 2: Mo phong ghi CSDL (PostgreSQL mock)
    const dbSpan = tracer.startSpan('database_save_order', {}, activeCtx);
    dbSpan.setAttribute('db.system', 'postgresql');
    dbSpan.setAttribute('db.name', 'shop_db');
    dbSpan.setAttribute('db.statement', 'INSERT INTO orders (customer_id, amount) VALUES ($1, $2)');
    
    // Mo phong do tre ghi CSDL khoang 40ms
    await new Promise(resolve => setTimeout(resolve, 40));
    dbSpan.end();

    const orderId = 'ORD-' + Math.floor(100000 + Math.random() * 900000);
    const traceId = rootSpan.spanContext().traceId;

    rootSpan.setAttribute('order.id', orderId);
    rootSpan.setStatus({ code: SpanStatusCode.OK });
    rootSpan.end();

    res.status(201).json({
      status: 'ORDER_CREATED',
      orderId: orderId,
      traceId: traceId,
      message: 'Don hang da duoc tiep nhan va khoi tao thanh cong'
    });
  } catch (error) {
    rootSpan.recordException(error);
    rootSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    rootSpan.end();
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order Service dang lang nghe tai cong ${PORT}`);
});
EOF
```{{exec}}

---

### 2.3. Khởi chạy Order Service và gửi request thử nghiệm

Trước khi chạy, đảm bảo cổng **3000** không bị chiếm dụng và khởi động **order-service.js** dưới dạng tiến trình nền:

```bash
fuser -k 3000/tcp 2>/dev/null || true
node /root/tracing-lab/order-service.js > /root/tracing-lab/order-service.log 2>&1 &
sleep 2
curl -s http://localhost:3000/health | jq .
```{{exec}}

Gửi một yêu cầu tạo đơn hàng hợp lệ:

```bash
curl -s -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust_vip_888",
    "items": [{"id": "item_1", "qty": 2}, {"id": "item_2", "qty": 1}],
    "totalAmount": 450
  }' | jq .
```{{exec}}

Đầu ra phản hồi sẽ trả về mã **orderId** cùng **traceId** tương ứng:

```json
{
  "status": "ORDER_CREATED",
  "orderId": "ORD-123456",
  "traceId": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "message": "Don hang da duoc tiep nhan va khoi tao thanh cong"
}
```

Kiểm tra API Jaeger để xác nhận Trace đầu tiên đã được đẩy thành công về backend:

```bash
curl -s "http://localhost:16686/api/traces?service=order-service" | jq '.data[0].spans[] | {operationName, spanID, duration}'
```{{exec}}

Bạn sẽ thấy 3 Span tương ứng trong một Trace:
1. **POST /api/orders** (Root Span)
2. **validate_payload** (Child Span 1)
3. **database_save_order** (Child Span 2)

Hãy mở [Jaeger UI]({{TRAFFIC_HOST1_16686}}), chọn Service là **order-service**, bấm **Find Traces** và nhấp vào kết quả để xem biểu đồ Timeline (Waterfall) đầu tiên!

Bấm **Check** để hoàn thành bước 2.
