#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/promql-lab/app
cd /root/promql-lab

# 1. Cai dat Node.js neu chua co
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" != v22* ]]; then
  curl -fsSL https://nodejs.org/dist/v22.12.0/node-v22.12.0-linux-x64.tar.gz | tar -xz -C /opt 2>/dev/null || true
  ln -sf /opt/node-v22.12.0-linux-x64/bin/node /usr/local/bin/node 2>/dev/null || true
  ln -sf /opt/node-v22.12.0-linux-x64/bin/npm /usr/local/bin/npm 2>/dev/null || true
fi

export PATH="/usr/local/bin:/opt/node-v22.12.0-linux-x64/bin:$PATH"

# 2. Khoi tao package.json va cai dat prom-client
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
npm install --no-audit --no-fund > /dev/null 2>&1 || true

# 3. Khoi tao ung dung mau Ecommerce API da instrument day du Metrics
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

// 2. Histogram: Thoi gian xu ly request phan theo buckets
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path', 'status'],
  buckets: [0.02, 0.05, 0.1, 0.2, 0.5, 1, 2]
});
register.registerMetric(httpRequestDuration);

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
      httpRequestTotal.inc({ method: req.method, path, status: res.statusCode });
      httpRequestDuration.observe({ method: req.method, path, status: res.statusCode }, duration);
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

# 4. Khoi tao tep cau hinh prometheus.yml
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

# 5. Khoi chay cac container
docker rm -f node-exporter prometheus > /dev/null 2>&1 || true
pkill -f "server.js" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# Node Exporter
docker run -d --name node-exporter \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.0 \
  --path.rootfs=/host > /dev/null 2>&1

# App API
nohup node /root/promql-lab/app/server.js > /root/promql-lab/app.log 2>&1 &
sleep 2

# Prometheus Server
docker run -d --name prometheus \
  --network host \
  -v /root/promql-lab:/etc/prometheus \
  prom/prometheus:v2.51.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle > /dev/null 2>&1

# 6. Khoi dong Traffic Generator ngam sinh so lieu bien thien realtime
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

touch /tmp/background-finished
