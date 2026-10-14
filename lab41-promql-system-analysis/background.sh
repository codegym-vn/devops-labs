#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/promql-lab/app
cd /root/promql-lab

# 1. Cai dat Node.js neu chua co (bo sung bo tro an toan)
if command -v node >/dev/null 2>&1; then
  echo "Node.js da duoc cai dat: $(node -v)"
elif [ -f /opt/node-v22.12.0-linux-x64/bin/node ]; then
  ln -sf /opt/node-v22.12.0-linux-x64/bin/node /usr/local/bin/node 2>/dev/null || true
  ln -sf /opt/node-v22.12.0-linux-x64/bin/npm /usr/local/bin/npm 2>/dev/null || true
fi

export PATH="/usr/local/bin:/opt/node-v22.12.0-linux-x64/bin:$PATH"

# 2. Khoi tao package.json
cat << 'EOF' > /root/promql-lab/app/package.json
{
  "name": "ecommerce-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "prom-client": "^15.1.2"
  }
}
EOF

cd /root/promql-lab/app
if command -v npm >/dev/null 2>&1; then
  npm install --no-audit --no-fund > /dev/null 2>&1 || true
fi

# 3. Khoi tao ung dung mau Ecommerce API bang Node.js
cat << 'EOF' > /root/promql-lab/app/server.js
const express = require('express');
const client = require('prom-client');

const app = express();
app.use(express.json());

const register = new client.Registry();
client.collectDefaultMetrics({ register });

// 1. Counter: Tong so request phan theo method, path, status
const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests processed',
  labelNames: ['method', 'path', 'status']
});
register.registerMetric(httpRequestTotal);

// Pre-seed metrics ban dau
httpRequestTotal.inc({ method: 'GET', path: '/api/products', status: '200' }, 15);
httpRequestTotal.inc({ method: 'GET', path: '/api/products', status: '500' }, 1);
httpRequestTotal.inc({ method: 'POST', path: '/api/orders', status: '201' }, 12);
httpRequestTotal.inc({ method: 'POST', path: '/api/orders', status: '400' }, 2);
httpRequestTotal.inc({ method: 'POST', path: '/api/orders', status: '500' }, 1);
httpRequestTotal.inc({ method: 'GET', path: '/api/users', status: '200' }, 20);

// 2. Histogram: Thoi gian xu ly request phan theo buckets
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path', 'status'],
  buckets: [0.02, 0.05, 0.1, 0.2, 0.5, 1, 2]
});
register.registerMetric(httpRequestDuration);

// Pre-seed histogram
httpRequestDuration.observe({ method: 'POST', path: '/api/orders', status: '201' }, 0.12);
httpRequestDuration.observe({ method: 'GET', path: '/api/products', status: '200' }, 0.04);

// 3. Gauge: Nguoi dung truc tuyen bien thien
const activeUsersGauge = new client.Gauge({
  name: 'active_users_total',
  help: 'Current active connected users'
});
register.registerMetric(activeUsersGauge);

activeUsersGauge.set(85);
setInterval(() => {
  const delta = Math.floor(Math.random() * 15) - 7;
  let val = (activeUsersGauge.get()?.values[0]?.value || 85) + delta;
  if (val < 20) val = 20;
  if (val > 150) val = 150;
  activeUsersGauge.set(val);
}, 3000);

// Middleware do luong metrics tu dong
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const path = req.route ? req.route.path : req.path;
    if (path !== '/metrics') {
      httpRequestTotal.inc({ method: req.method, path, status: String(res.statusCode) });
      httpRequestDuration.observe({ method: req.method, path, status: String(res.statusCode) }, duration);
    }
  });
  next();
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/health', (req, res) => res.json({ status: 'UP' }));

app.get('/api/products', async (req, res) => {
  await new Promise(r => setTimeout(r, 20 + Math.random() * 40));
  if (Math.random() < 0.05) {
    return res.status(500).json({ error: 'Database connection failed' });
  }
  res.json([{ id: 1, name: 'Laptop' }, { id: 2, name: 'Phone' }]);
});

app.post('/api/orders', async (req, res) => {
  const rand = Math.random();
  await new Promise(r => setTimeout(r, 80 + Math.random() * 120));
  if (rand < 0.08) {
    return res.status(500).json({ error: 'Payment service error' });
  } else if (rand < 0.18) {
    return res.status(400).json({ error: 'Invalid order payload' });
  }
  res.status(201).json({ status: 'ORDER_CREATED', order_id: 'ord_' + Date.now() });
});

app.get('/api/users', async (req, res) => {
  await new Promise(r => setTimeout(r, 10 + Math.random() * 15));
  res.json({ users: 120 });
});

const PORT = 8080;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Ecommerce API listening on port ${PORT}`);
});
EOF

# 4. Khoi tao script Python 3 fallback hoan toan doc lap, khong can thu vien ngoai
cat << 'EOF' > /root/promql-lab/app/server.py
import http.server
import socketserver
import time
import random
import threading
import json

class MetricState:
    def __init__(self):
        self.lock = threading.Lock()
        self.products_get_200 = 25
        self.products_get_500 = 1
        self.orders_post_201 = 20
        self.orders_post_400 = 3
        self.orders_post_500 = 2
        self.users_get_200 = 30
        self.active_users = 85
        self.bucket_bounds = [0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]
        self.buckets = {0.02: 15, 0.05: 35, 0.1: 55, 0.2: 72, 0.5: 80, 1.0: 81, 2.0: 81}
        self.bucket_inf = 81
        self.duration_sum = 9.85
        self.duration_count = 81

    def record_request(self, method, path, status, duration):
        with self.lock:
            if path == '/api/products':
                if status == 200: self.products_get_200 += 1
                else: self.products_get_500 += 1
            elif path == '/api/orders':
                if status == 201: self.orders_post_201 += 1
                elif status == 400: self.orders_post_400 += 1
                else: self.orders_post_500 += 1
            elif path == '/api/users':
                self.users_get_200 += 1
            
            self.duration_count += 1
            self.duration_sum += duration
            for b in self.bucket_bounds:
                if duration <= b:
                    self.buckets[b] += 1
            self.bucket_inf += 1

    def get_metrics_text(self):
        with self.lock:
            lines = [
                "# HELP http_requests_total Total number of HTTP requests processed",
                "# TYPE http_requests_total counter",
                f'http_requests_total{{method="GET",path="/api/products",status="200"}} {self.products_get_200}',
                f'http_requests_total{{method="GET",path="/api/products",status="500"}} {self.products_get_500}',
                f'http_requests_total{{method="POST",path="/api/orders",status="201"}} {self.orders_post_201}',
                f'http_requests_total{{method="POST",path="/api/orders",status="400"}} {self.orders_post_400}',
                f'http_requests_total{{method="POST",path="/api/orders",status="500"}} {self.orders_post_500}',
                f'http_requests_total{{method="GET",path="/api/users",status="200"}} {self.users_get_200}',
                "",
                "# HELP http_request_duration_seconds HTTP request duration in seconds",
                "# TYPE http_request_duration_seconds histogram"
            ]
            for b in self.bucket_bounds:
                lines.append(f'http_request_duration_seconds_bucket{{le="{b}"}} {self.buckets[b]}')
            lines.append(f'http_request_duration_seconds_bucket{{le="+Inf"}} {self.bucket_inf}')
            lines.append(f'http_request_duration_seconds_sum {self.duration_sum:.4f}')
            lines.append(f'http_request_duration_seconds_count {self.duration_count}')
            lines.append("")
            lines.append("# HELP active_users_total Current active connected users")
            lines.append("# TYPE active_users_total gauge")
            lines.append(f"active_users_total {self.active_users}")
            lines.append("")
            return "\n".join(lines)

metrics = MetricState()

def simulate_background():
    while True:
        time.sleep(1)
        delta = random.randint(-5, 5)
        metrics.active_users = max(20, min(150, metrics.active_users + delta))
        dur = random.uniform(0.01, 0.25)
        r = random.random()
        if r < 0.6:
            metrics.record_request('GET', '/api/products', 200, dur)
        elif r < 0.85:
            metrics.record_request('POST', '/api/orders', 201, dur)
        elif r < 0.95:
            metrics.record_request('POST', '/api/orders', 400, dur)
        else:
            metrics.record_request('POST', '/api/orders', 500, dur)

threading.Thread(target=simulate_background, daemon=True).start()

class MockHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        start = time.time()
        if self.path == '/metrics':
            content = metrics.get_metrics_text().encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/health':
            content = json.dumps({"status": "UP"}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/api/products':
            time.sleep(random.uniform(0.02, 0.06))
            is_err = random.random() < 0.05
            code = 500 if is_err else 200
            content = json.dumps({"error": "DB error"} if is_err else [{"id": 1, "name": "Laptop"}]).encode('utf-8')
            self.send_response(code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
            metrics.record_request('GET', '/api/products', code, time.time() - start)
        elif self.path == '/api/users':
            content = json.dumps({"users": 120}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
            metrics.record_request('GET', '/api/users', 200, time.time() - start)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        start = time.time()
        if self.path == '/api/orders':
            time.sleep(random.uniform(0.05, 0.15))
            r = random.random()
            if r < 0.1:
                code = 500
                data = {"error": "Payment service error"}
            elif r < 0.2:
                code = 400
                data = {"error": "Invalid order payload"}
            else:
                code = 201
                data = {"status": "ORDER_CREATED", "order_id": f"ord_{int(time.time()*1000)}"}
            content = json.dumps(data).encode('utf-8')
            self.send_response(code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
            metrics.record_request('POST', '/api/orders', code, time.time() - start)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = socketserver.TCPServer(('0.0.0.0', 8080), MockHandler)
    server.allow_reuse_address = True
    print("Serving Ecommerce API on port 8080")
    server.serve_forever()
EOF

# 5. Khoi tao tep cau hinh prometheus.yml
cat << 'EOF' > /root/promql-lab/prometheus.yml
global:
  scrape_interval: 2s
  evaluation_interval: 2s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          environment: 'production'
          instance: 'srv-prod-01'

  - job_name: 'ecommerce-api'
    static_configs:
      - targets: ['localhost:8080']
        labels:
          environment: 'production'
          tier: 'backend'
EOF

# 6. Khoi chay cac service
docker rm -f node-exporter prometheus > /dev/null 2>&1 || true
pkill -f "server.js" > /dev/null 2>&1 || true
pkill -f "server.py" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# Node Exporter
docker run -d --name node-exporter \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.0 \
  --path.rootfs=/host > /dev/null 2>&1

# App API: Thu chay bang Node.js, neu khong thanh cong thi tu dong fallback ve Python 3
STARTED=0
if command -v node >/dev/null 2>&1 && [ -d /root/promql-lab/app/node_modules/express ]; then
  nohup node /root/promql-lab/app/server.js > /root/promql-lab/app.log 2>&1 &
  sleep 1
  if curl -s http://localhost:8080/health | grep -q "UP"; then
    STARTED=1
  fi
fi

if [ "$STARTED" -eq 0 ]; then
  nohup python3 /root/promql-lab/app/server.py > /root/promql-lab/app.log 2>&1 &
  sleep 1
fi

# Prometheus Server
docker run -d --name prometheus \
  --network host \
  -v /root/promql-lab:/etc/prometheus \
  prom/prometheus:v2.51.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle > /dev/null 2>&1

# 7. Khoi dong Traffic Generator ngam sinh so lieu bien thien realtime
cat << 'EOF' > /root/promql-lab/traffic-generator.sh
#!/bin/bash
while true; do
  curl -s http://localhost:8080/api/products > /dev/null 2>&1 &
  curl -s -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"amount":100}' > /dev/null 2>&1 &
  curl -s http://localhost:8080/api/users > /dev/null 2>&1 &
  sleep 0.5
done
EOF
chmod +x /root/promql-lab/traffic-generator.sh
nohup /root/promql-lab/traffic-generator.sh > /dev/null 2>&1 &

# Cho Prometheus thuc hien scrape it nhat 1 chu ky (2 giay)
sleep 3

touch /tmp/background-finished

