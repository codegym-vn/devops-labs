# Bước 2: Cài Đặt Custom Metrics Counter, Histogram & Gauge

Chỉ số tài nguyên hệ điều hành là chưa đủ để hiểu được trải nghiệm của người dùng. Trong bước này, bạn sẽ triển khai ba loại Custom Metrics chuẩn của Prometheus và tạo một Express Middleware tự động đo lường mọi HTTP request gửi đến hệ thống.

---

### 1. Ba loại Metric nghiệp vụ cốt lõi trong Prometheus

1. **Counter (`http_requests_total`):** Là thước đo chỉ tăng lũy kế theo thời gian (hoặc reset về 0 khi dịch vụ khởi động lại). Phù hợp để đếm tổng số lượt truy cập API, phân loại theo nhãn (Labels) như phương thức `method`, đường dẫn `route`, và mã trạng thái `status_code`.
2. **Histogram (`http_request_duration_seconds`):** Đo lường và phân phối các quan sát vào từng khoảng giới hạn (Buckets). Là công cụ duy nhất giúp tính toán chính xác độ trễ phân vị p50, p90, p95, p99 (ví dụ: 95% người dùng nhận kết quả dưới 200ms).
3. **Gauge (`active_requests`):** Đo lường giá trị tức thời có thể tăng hoặc giảm liên tục theo thời gian thực (số lượng request đang được xử lý đồng thời, số kết nối cơ sở dữ liệu mở).

---

### 2. Cài đặt Custom Metrics và Middleware đo lường

Cập nhật mã nguồn `server.js` để tích hợp Counter, Histogram, Gauge và Express Middleware:

```bash
cd /root/app-monitoring-lab
cat << 'EOF' > server.js
const express = require('express');
const client = require('prom-client');

const app = express();
app.use(express.json());

// 1. Kich hoat bo thu thap mac dinh cua Node.js runtime
client.collectDefaultMetrics({ register: client.register });

// 2. Khoi tao cac Custom Metrics
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Tong so luot yeu cau HTTP den ung dung',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDurationHistogram = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Phan phoi do tre phan hoi HTTP theo giay',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.2, 0.3, 0.5, 1, 2] // Cac moc tu 50ms den 2 giay
});

const activeRequestsGauge = new client.Gauge({
  name: 'active_requests',
  help: 'So luong HTTP request dang duoc xu ly dong thoi'
});

// 3. Middleware tu dong do luong moi HTTP request
app.use((req, res, next) => {
  if (req.path === '/metrics' || req.path === '/health') {
    return next();
  }

  activeRequestsGauge.inc();
  const startTime = Date.now();

  res.on('finish', () => {
    activeRequestsGauge.dec();
    const durationSeconds = (Date.now() - startTime) / 1000;
    const routeName = req.route ? req.route.path : req.path;

    httpRequestCounter.inc({
      method: req.method,
      route: routeName,
      status_code: res.statusCode
    });

    httpRequestDurationHistogram.observe(
      {
        method: req.method,
        route: routeName,
        status_code: res.statusCode
      },
      durationSeconds
    );
  });

  next();
});

// Endpoint xu ly lay danh sach don hang
app.get('/api/orders', (req, res) => {
  res.json({
    status: 'SUCCESS',
    orders: [
      { id: 101, item: 'Laptop Dell XPS', amount: 1500 },
      { id: 102, item: 'Ban phim co Keychron', amount: 95 }
    ]
  });
});

// Endpoint xu ly thanh toan (mo phong do tre va loi 500 ngau nhien)
app.post('/api/checkout', (req, res) => {
  const isError = Math.random() < 0.25; // 25% xac suat loi 500
  const delay = Math.floor(Math.random() * 250) + 50; // Do tre tu 50ms den 300ms

  setTimeout(() => {
    if (isError) {
      return res.status(500).json({ status: 'FAILED', message: 'Cong thanh toan khong phan hoi' });
    }
    res.json({ status: 'COMPLETED', transactionId: 'txn_' + Date.now() });
  }, delay);
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-api' });
});

// Expose endpoint /metrics cho Prometheus scrape
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order API Service dang chay tren cong ${PORT}`);
});
EOF
```{{exec}}

---

### 3. Khởi động lại ứng dụng và kích hoạt số liệu đo lường

Khởi động lại tiến trình Node.js:

```bash
pkill -f "node server.js" 2>/dev/null || true
nohup node server.js > app.log 2>&1 & sleep 2
curl -s http://localhost:3000/health | jq .
```{{exec}}

Gửi một số request thử nghiệm để kích hoạt Counter và Histogram:

```bash
curl -s http://localhost:3000/api/orders > /dev/null
curl -s -X POST http://localhost:3000/api/checkout > /dev/null
curl -s -X POST http://localhost:3000/api/checkout > /dev/null
```{{exec}}

Kiểm tra số liệu Counter vừa được ghi nhận tại `/metrics`:

```bash
curl -s http://localhost:3000/metrics | grep -E "http_requests_total\{"
```{{exec}}

Kiểm tra các bucket thời gian của Histogram:

```bash
curl -s http://localhost:3000/metrics | grep -E "http_request_duration_seconds_bucket" | head -n 10
```{{exec}}

Mỗi request đi qua hệ thống đều tự động tăng chỉ số counter và được phân loại vào đúng bucket thời gian xử lý.

Nhấn **Check** để hoàn thành bước 2.
