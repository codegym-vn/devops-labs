# Bước 1: Khởi Tạo Ứng Dụng & Cài Đặt prom-client

Trong bước này, bạn sẽ cài đặt môi trường Node.js, cài đặt thư viện đo lường chuẩn ngành **prom-client**, kích hoạt bộ thu thập các chỉ số runtime mặc định (Default Metrics) và mở endpoint **/metrics**.

---

### 1. Cài đặt Node.js và jq

Cài đặt Node.js phiên bản 18 dạng binary và tiện ích xử lý JSON:

```bash
curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.gz | tar -xz -C /opt && ln -sf /opt/node-v18.20.4-linux-x64/bin/node /usr/local/bin/node && ln -sf /opt/node-v18.20.4-linux-x64/bin/npm /usr/local/bin/npm && node -v && npm -v
```{{exec}}

```bash
apt-get update -qq && apt-get install -y -qq jq > /dev/null && echo "Da cai xong jq"
```{{exec}}

---

### 2. Cài đặt các gói thư viện phụ thuộc

Di chuyển vào thư mục dự án và cài đặt **express** cùng **prom-client**:

```bash
cd /root/app-monitoring-lab && npm install --no-audit --no-fund
```{{exec}}

---

### 3. Tích hợp prom-client và mở endpoint /metrics

Thư viện **prom-client** là client Prometheus chính thức cho Node.js, hỗ trợ tự động thu thập thông số tài nguyên của tiến trình và định dạng dữ liệu chuẩn OpenMetrics.

Cập nhật **server.js** để kích hoạt **collectDefaultMetrics** và expose route **/metrics**:

```bash
cd /root/app-monitoring-lab
cat << 'EOF' > server.js
const express = require('express');
const client = require('prom-client');

const app = express();
app.use(express.json());

// 1. Kich hoat bo thu thap chi so mac dinh cua tien trinh (CPU, Memory, Event Loop)
client.collectDefaultMetrics({ register: client.register });

// 2. Expose endpoint /metrics theo chuan dinh dang Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

// Endpoint 1: Xu ly lay danh sach don hang
app.get('/api/orders', (req, res) => {
  res.json({
    status: 'SUCCESS',
    orders: [
      { id: 101, item: 'Laptop Dell XPS', amount: 1500 },
      { id: 102, item: 'Ban phim co Keychron', amount: 95 }
    ]
  });
});

// Endpoint 2: Xu ly thanh toan (mo phong do tre va loi 500)
app.post('/api/checkout', (req, res) => {
  const isError = Math.random() < 0.2; // 20% xac suat loi
  const delay = Math.floor(Math.random() * 250) + 50; // Do tre tu 50ms - 300ms

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

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order API dang chay tren cong ${PORT}`);
});
EOF
echo "Da tich hop prom-client vao server.js thanh cong"
```{{exec}}

Kiểm tra nội dung **server.js** sau khi chèn mã:

```bash
head -n 25 server.js
```{{exec}}

---

### 4. Khởi chạy ứng dụng và khảo sát endpoint /metrics

Khởi chạy ứng dụng ở chế độ nền trên cổng 3000:

```bash
fuser -k 3000/tcp 2>/dev/null || true
pkill -f "node server.js" 2>/dev/null || true
sleep 1
nohup node server.js > app.log 2>&1 & sleep 2
curl -s http://localhost:3000/health | jq .
```{{exec}}

Truy vấn endpoint **/metrics** để xem dữ liệu telemetry thời gian thực:

```bash
curl -s http://localhost:3000/metrics | head -n 35
```{{exec}}

Quan sát các chỉ số mặc định được sinh ra:
* **process_cpu_user_seconds_total**: Tổng thời gian CPU mà tiến trình Node.js đã sử dụng.
* **nodejs_heap_size_used_bytes**: Dung lượng bộ nhớ Heap RAM thực tế đang dùng.
* **nodejs_eventloop_lag_seconds**: Độ trễ của vòng lặp sự kiện Event Loop (chỉ số vàng để phát hiện ứng dụng Node.js bị nghẽn blocking I/O).

Nhấn **Check** để hoàn thành bước 1.
