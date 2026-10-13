### 3.1. Xây dựng Payment Service với cơ chế trích xuất Context (Context Extraction)

Trong kiến trúc Microservices, khi một dịch vụ gọi sang dịch vụ khác qua giao thức mạng (HTTP/gRPC), ranh giới tiến trình (Process Boundary) bị phá vỡ. Nếu không truyền thông tin ngữ cảnh, dịch vụ nhận sẽ tự khởi tạo một **Trace ID** mới tinh, làm đứt gãy hành trình truy vết.

Để giải quyết vấn đề này, dịch vụ nhận (**Payment Service**) cần:
1. Đọc các HTTP Header đến (**req.headers**).
2. Sử dụng OpenTelemetry Propagator để trích xuất (**extract**) đối tượng **parentCtx** từ header **traceparent** chuẩn W3C.
3. Khởi tạo Span đầu tiên bên trong dịch vụ nhận làm **Child Span** của Span cha từ dịch vụ gọi.

Chạy lệnh sau để tạo tệp **payment-service.js** lắng nghe trên cổng **8081**:

```bash
cat << 'EOF' > /root/tracing-lab/payment-service.js
const express = require('express');
const { initTracer, trace, context, propagation, SpanStatusCode } = require('./tracer');

const { tracer } = initTracer('payment-service');
const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'payment-service' });
});

// Endpoint xu ly thanh toan voi Context Extraction
app.post('/api/pay', async (req, res) => {
  // 1. Trich xuat Trace Context tu HTTP Headers den (W3C traceparent)
  const parentCtx = propagation.extract(context.active(), req.headers);

  // 2. Khoi tao Span lien ket voi Context cha tu Order Service
  const paymentSpan = tracer.startSpan('process_payment_transaction', {}, parentCtx);
  paymentSpan.setAttribute('payment.service', 'payment-service');
  paymentSpan.setAttribute('payment.amount', req.body.amount || 0);
  paymentSpan.setAttribute('payment.currency', 'USD');

  const activeCtx = trace.setSpan(parentCtx, paymentSpan);

  try {
    // 3. Child Span: Kiem tra gian lan & han muc the (Fraud Check)
    const fraudSpan = tracer.startSpan('fraud_and_credit_check', {}, activeCtx);
    fraudSpan.setAttribute('fraud.algorithm', 'rule_engine_v2');
    
    // Mo phong thoi gian kiem tra khoang 35ms
    await new Promise(resolve => setTimeout(resolve, 35));
    fraudSpan.end();

    // 4. Hoan tat giao dich
    paymentSpan.setStatus({ code: SpanStatusCode.OK });
    paymentSpan.end();

    const transactionId = 'TXN-' + Math.floor(100000 + Math.random() * 900000);
    res.json({
      status: 'PAID',
      transactionId: transactionId,
      traceId: paymentSpan.spanContext().traceId
    });
  } catch (error) {
    paymentSpan.recordException(error);
    paymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    paymentSpan.end();
    res.status(500).json({ error: error.message });
  }
});

const PORT = 8081;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Payment Service dang lang nghe tai cong ${PORT}`);
});
EOF
```{{exec}}

---

### 3.2. Cập nhật Order Service để tiêm Context (Context Injection)

Bây giờ, chúng ta sẽ cập nhật **order-service.js** để sau khi lưu đơn hàng vào CSDL, dịch vụ sẽ:
1. Tạo một Child Span mang tên **call_payment_gateway**.
2. Sử dụng **propagation.inject()** để tự động gắn header **traceparent** vào request gửi sang Payment Service.
3. Gửi HTTP POST tới **http://localhost:8081/api/pay** bằng hàm **fetch** có sẵn của Node.js.

Chạy lệnh sau để ghi đè **order-service.js**:

```bash
cat << 'EOF' > /root/tracing-lab/order-service.js
const express = require('express');
const { initTracer, trace, context, propagation, SpanStatusCode } = require('./tracer');

const { tracer } = initTracer('order-service');
const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-service' });
});

app.post('/api/orders', async (req, res) => {
  const { customerId, items, totalAmount } = req.body;
  
  const rootSpan = tracer.startSpan('POST /api/orders');
  rootSpan.setAttribute('http.method', 'POST');
  rootSpan.setAttribute('http.route', '/api/orders');
  rootSpan.setAttribute('customer.id', customerId || 'anonymous');
  rootSpan.setAttribute('order.amount', totalAmount || 0);

  const activeCtx = trace.setSpan(context.active(), rootSpan);

  try {
    // 1. Child Span: Validate
    const valSpan = tracer.startSpan('validate_payload', {}, activeCtx);
    if (!items || items.length === 0) {
      valSpan.setStatus({ code: SpanStatusCode.ERROR, message: 'Danh sach san pham trong' });
      valSpan.end();
      rootSpan.setStatus({ code: SpanStatusCode.ERROR, message: 'Invalid payload' });
      rootSpan.end();
      return res.status(400).json({ error: 'Danh sach mat hang khong duoc de trong' });
    }
    valSpan.addEvent('validation_success', { items_count: items.length });
    valSpan.end();

    // 2. Child Span: Database Save
    const dbSpan = tracer.startSpan('database_save_order', {}, activeCtx);
    dbSpan.setAttribute('db.system', 'postgresql');
    dbSpan.setAttribute('db.statement', 'INSERT INTO orders (customer_id, amount) VALUES ($1, $2)');
    await new Promise(resolve => setTimeout(resolve, 40));
    dbSpan.end();

    const orderId = 'ORD-' + Math.floor(100000 + Math.random() * 900000);
    rootSpan.setAttribute('order.id', orderId);

    // 3. Child Span: Goi Payment Service kem Context Injection
    const paymentCallSpan = tracer.startSpan('call_payment_gateway', {}, activeCtx);
    paymentCallSpan.setAttribute('peer.service', 'payment-service');
    paymentCallSpan.setAttribute('http.url', 'http://localhost:8081/api/pay');

    const paymentCallCtx = trace.setSpan(activeCtx, paymentCallSpan);

    // Inject Trace Context vao HTTP Headers
    const outgoingHeaders = {
      'Content-Type': 'application/json'
    };
    propagation.inject(paymentCallCtx, outgoingHeaders);

    console.log(`[Order Service] Header duoc inject qua mang: traceparent = ${outgoingHeaders.traceparent}`);

    const paymentResponse = await fetch('http://localhost:8081/api/pay', {
      method: 'POST',
      headers: outgoingHeaders,
      body: JSON.stringify({
        orderId: orderId,
        amount: totalAmount
      })
    });

    const paymentData = await paymentResponse.json();
    paymentCallSpan.setAttribute('http.status_code', paymentResponse.status);
    paymentCallSpan.end();

    if (!paymentResponse.ok) {
      throw new Error(`Payment Service that bai voi ma loi ${paymentResponse.status}: ${paymentData.error}`);
    }

    rootSpan.setStatus({ code: SpanStatusCode.OK });
    rootSpan.end();

    res.status(201).json({
      status: 'SUCCESS',
      orderId: orderId,
      transactionId: paymentData.transactionId,
      traceId: rootSpan.spanContext().traceId,
      message: 'Giao dich da duoc xu ly xuyen suot 2 microservices'
    });
  } catch (error) {
    rootSpan.recordException(error);
    rootSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    rootSpan.end();
    res.status(500).json({ error: error.message });
  }
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order Service dang lang nghe tai cong ${PORT}`);
});
EOF
```{{exec}}

---

### 3.3. Khởi chạy 2 Microservices & Thực hiện giao dịch xuyên suốt

Khởi động **Payment Service** trên cổng **8081** và khởi động lại **Order Service** trên cổng **3000**:

```bash
fuser -k 3000/tcp 2>/dev/null || true
fuser -k 8081/tcp 2>/dev/null || true

node /root/tracing-lab/payment-service.js > /root/tracing-lab/payment-service.log 2>&1 &
node /root/tracing-lab/order-service.js > /root/tracing-lab/order-service.log 2>&1 &

sleep 2
curl -s http://localhost:8081/health | jq .
curl -s http://localhost:3000/health | jq .
```{{exec}}

Gửi một yêu cầu tạo đơn hàng tích hợp thanh toán liên dịch vụ:

```bash
curl -s -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust_gold_99",
    "items": [{"id": "macbook_pro_m3", "qty": 1}],
    "totalAmount": 2400
  }' | jq .
```{{exec}}

Kiểm tra log của Order Service để xem định dạng header **traceparent** đã được tiêm tự động:

```bash
tail -n 5 /root/tracing-lab/order-service.log
```{{exec}}

Bạn sẽ thấy dòng log có định dạng W3C Trace Context:
**traceparent = 00-{trace_id}-{span_id}-01**

Kiểm tra API Jaeger để kiểm chứng Trace mới nhất chứa Spans từ CẢ HAI dịch vụ:

```bash
curl -s "http://localhost:16686/api/traces?service=order-service&limit=1" | jq '{
  traceID: .data[0].traceID,
  totalSpans: (.data[0].spans | length),
  services: [.data[0].processes[].serviceName],
  spanTree: [.data[0].spans[] | {service: .processID, name: .operationName}]
}'
```{{exec}}

Hãy mở <a href="{{TRAFFIC_HOST1_16686}}" target="_blank">Jaeger UI</a> (mở sang tab mới), tải lại trang và chọn Trace mới nhất. Bạn sẽ thấy biểu đồ Waterfall hiển thị cấu trúc phân cấp đa tầng:
- **order-service**: POST /api/orders
  - **order-service**: validate_payload
  - **order-service**: database_save_order
  - **order-service**: call_payment_gateway
    - **payment-service**: process_payment_transaction
      - **payment-service**: fraud_and_credit_check

Cả 5 Span này đều sở hữu chung một **Trace ID** duy nhất!

Bấm **Check** để hoàn thành bước 3.
