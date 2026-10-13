### 4.1. Nâng cấp Payment Service để mô phỏng Lỗi & Độ trễ nghẽn cổ chai

Trong thực tế vận hành hạ tầng, hai vấn đề nhức nhối nhất là:
1. **Lỗi phân tán (Distributed Errors)**: Một dịch vụ cấp sâu (Downstream) bị lỗi khiến toàn bộ chuỗi giao dịch sụp đổ, nhưng log của dịch vụ Gateway chỉ ghi nhận chung chung là **500 Internal Server Error**.
2. **Nút thắt cổ chai (Latency Bottlenecks)**: Thời gian phản hồi tăng đột biến nhưng không rõ do CSDL, do dịch vụ bên thứ ba hay do tính toán nội bộ.

Chúng ta sẽ cập nhật **payment-service.js** để xử lý 2 kịch bản này:
- Nếu số tiền thanh toán vượt quá **5000**, ném ngoại lệ **Credit Limit Exceeded**, ghi nhận bằng **recordException** và đánh dấu trạng thái Span là **SpanStatusCode.ERROR**.
- Nếu có header **x-simulate-delay: true**, kích hoạt độ trễ bất thường **650ms** tại công đoạn kiểm tra tín dụng.

Chạy lệnh sau để cập nhật **payment-service.js**:

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

app.post('/api/pay', async (req, res) => {
  const parentCtx = propagation.extract(context.active(), req.headers);
  const paymentSpan = tracer.startSpan('process_payment_transaction', {}, parentCtx);
  paymentSpan.setAttribute('payment.service', 'payment-service');
  paymentSpan.setAttribute('payment.amount', req.body.amount || 0);

  const activeCtx = trace.setSpan(parentCtx, paymentSpan);

  try {
    const isSimulateSlow = req.headers['x-simulate-delay'] === 'true';
    const amount = Number(req.body.amount || 0);

    const fraudSpan = tracer.startSpan('fraud_and_credit_check', {}, activeCtx);
    fraudSpan.setAttribute('fraud.algorithm', 'rule_engine_v2');

    // Kich ban 1: Mo phong do tre bat thuong (Bottleneck)
    if (isSimulateSlow) {
      fraudSpan.setAttribute('latency.simulation', 'slow_third_party_gateway');
      await new Promise(resolve => setTimeout(resolve, 650));
    } else {
      await new Promise(resolve => setTimeout(resolve, 35));
    }

    // Kich ban 2: Mo phong loi nghiep vu khi so tien > 5000
    if (amount > 5000) {
      const limitErr = new Error(`Giao dich tu choi: So tien $${amount} vuot qua han muc the ($5000)!`);
      // Ghi nhan Exception truc tiep vao Span Event va Stack Trace
      fraudSpan.recordException(limitErr);
      fraudSpan.setStatus({ code: SpanStatusCode.ERROR, message: limitErr.message });
      fraudSpan.end();

      throw limitErr;
    }

    fraudSpan.setStatus({ code: SpanStatusCode.OK });
    fraudSpan.end();

    paymentSpan.setStatus({ code: SpanStatusCode.OK });
    paymentSpan.end();

    res.json({
      status: 'PAID',
      transactionId: 'TXN-' + Math.floor(100000 + Math.random() * 900000),
      traceId: paymentSpan.spanContext().traceId
    });
  } catch (error) {
    paymentSpan.recordException(error);
    paymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    paymentSpan.end();
    res.status(402).json({ error: error.message });
  }
});

const PORT = 8081;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Payment Service dang lang nghe tai cong ${PORT}`);
});
EOF
```{{exec}}

Khởi động lại **payment-service.js**:

```bash
fuser -k 8081/tcp 2>/dev/null || true
node /root/tracing-lab/payment-service.js > /root/tracing-lab/payment-service.log 2>&1 &
sleep 2
curl -s http://localhost:8081/health | jq .
```{{exec}}

---

### 4.2. Kích hoạt và phân tích lỗi phân tán (Distributed Error Analysis)

Gửi một đơn hàng có giá trị **8500** (vượt hạn mức 5000) để kích hoạt kịch bản lỗi:

```bash
curl -s -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust_fraud_test",
    "items": [{"id": "diamond_ring", "qty": 1}],
    "totalAmount": 8500
  }' | jq .
```{{exec}}

Phản hồi từ Order Service trả về mã lỗi 500 do Payment Service từ chối thanh toán:

```json
{
  "error": "Payment Service that bai voi ma loi 402: Giao dich tu choi: So tien $8500 vuot qua han muc the ($5000)!"
}
```

Mở [Jaeger UI]({{TRAFFIC_HOST1_16686}}):
1. Tại ô **Service**, chọn **order-service**.
2. Nhấn **Find Traces**.
3. Bạn sẽ thấy Trace mới nhất xuất hiện một dấu chấm tròn đỏ báo hiệu lỗi (**error=true**).
4. Nhấp vào Trace để mở biểu đồ Waterfall. Bạn sẽ thấy cả **call_payment_gateway** và **fraud_and_credit_check** đều bị tô đỏ.
5. Nhấp mở rộng thanh Span **fraud_and_credit_check** -> Nhấp vào mục **Logs**: toàn bộ Exception Stack Trace với thông điệp lỗi chi tiết được hiển thị chuẩn xác mà không cần SSH vào từng container để xem log tệp!

---

### 4.3. Kích hoạt và phân tích nút thắt cổ chai (Bottleneck Analysis)

Cập nhật nhanh **order-service.js** để chuyển tiếp header **x-simulate-delay** nếu client truyền vào, sau đó gửi một request có độ trễ:

```bash
curl -s -X POST http://localhost:8081/api/pay \
  -H "Content-Type: application/json" \
  -H "x-simulate-delay: true" \
  -d '{
    "amount": 1200
  }' | jq .
```{{exec}}

Kiểm tra trên [Jaeger UI]({{TRAFFIC_HOST1_16686}}):
Chọn Service là **payment-service** và bấm **Find Traces**. Trên thanh Timeline, bạn sẽ thấy tổng thời gian thực thi lên tới hơn **680ms**, trong đó Span **fraud_and_credit_check** chiếm tới gần **95%** tổng thời gian thực hiện của toàn bộ request!

---

### 4.4. Trích xuất và Lưu trữ Báo Cáo Trace JSON

Để tích hợp vào các pipeline kiểm toán hoặc hệ thống giám sát tự động, chúng ta có thể truy xuất dữ liệu Trace bị lỗi dạng JSON qua API của Jaeger:

```bash
curl -s "http://localhost:16686/api/traces?service=payment-service&tags=%7B%22error%22%3A%22true%22%7D&limit=1" > /root/tracing-lab/error-trace.json
cat /root/tracing-lab/error-trace.json | jq '.data[0] | {
  traceID: .traceID,
  failedSpans: [.spans[] | select(.tags[].key == "error") | {name: .operationName, spanID: .spanID}]
}'
```{{exec}}

Kiểm tra tệp báo cáo JSON đã được tạo thành công:

```bash
ls -lh /root/tracing-lab/error-trace.json
```{{exec}}

Bấm **Check** để hoàn thành bài lab!
