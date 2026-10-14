#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/incident-lab
mkdir -p /root/incident-report
mkdir -p /var/log/apps
cd /root/incident-lab

# 1. Khoi tao package.json voi Express va OpenTelemetry SDK
cat << 'EOF' > package.json
{
  "name": "incident-lab",
  "version": "1.0.0",
  "description": "Root Cause Analysis Scenario - Distributed System Incident",
  "main": "order-service.js",
  "dependencies": {
    "express": "^4.19.2",
    "@opentelemetry/api": "^1.9.0",
    "@opentelemetry/sdk-node": "^0.52.1",
    "@opentelemetry/exporter-trace-otlp-http": "^0.52.1"
  }
}
EOF

# 2. Cai dat Node.js v22 (LTS) neu he thong chua co san
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" != v22* ]]; then
  curl -fsSL https://nodejs.org/dist/v22.12.0/node-v22.12.0-linux-x64.tar.gz | tar -xz -C /opt 2>/dev/null || true
  ln -sf /opt/node-v22.12.0-linux-x64/bin/node /usr/local/bin/node 2>/dev/null || true
  ln -sf /opt/node-v22.12.0-linux-x64/bin/npm /usr/local/bin/npm 2>/dev/null || true
fi

export PATH="/usr/local/bin:/opt/node-v22.12.0-linux-x64/bin:$PATH"
npm install --no-audit --no-fund > /dev/null 2>&1 || true

# 3. Khoi tao module OpenTelemetry Tracer dung chung
cat << 'EOF' > /root/incident-lab/tracer.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { trace, context, propagation, SpanStatusCode } = require('@opentelemetry/api');

function initTracer(serviceName) {
  const exporter = new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces',
  });

  const sdk = new NodeSDK({
    serviceName: serviceName,
    traceExporter: exporter,
  });

  sdk.start();

  const tracer = trace.getTracer(serviceName);
  return { tracer, sdk };
}

module.exports = {
  initTracer,
  trace,
  context,
  propagation,
  SpanStatusCode
};
EOF

# 4. Tao file cau hinh bien moi truong gay loi cho Payment Service (DB_POOL_MAX=2)
cat << 'EOF' > /root/incident-lab/payment-service.env
PORT=3002
DB_POOL_MAX=2
DB_TIMEOUT_MS=2000
DB_QUERY_LATENCY_MS=450
EOF

# 5. Trien khai Payment Service (chua loi Connection Pool Exhaustion)
cat << 'EOF' > /root/incident-lab/payment-service.js
const express = require('express');
const fs = require('fs');
const { initTracer, trace, context, propagation, SpanStatusCode } = require('./tracer');

const { tracer } = initTracer('payment-service');
const app = express();
app.use(express.json());

// Doc cau hinh tu file .env
function loadConfig() {
  const envPath = '/root/incident-lab/payment-service.env';
  let config = { DB_POOL_MAX: 2, DB_TIMEOUT_MS: 2000, DB_QUERY_LATENCY_MS: 450, PORT: 3002 };
  if (fs.existsSync(envPath)) {
    const lines = fs.readFileSync(envPath, 'utf8').split('\n');
    lines.forEach(line => {
      const parts = line.split('=');
      if (parts.length === 2) {
        config[parts[0].trim()] = parseInt(parts[1].trim(), 10) || parts[1].trim();
      }
    });
  }
  return config;
}

let config = loadConfig();

// Mo phong Database Connection Pool
let activeConnections = 0;
const waitQueue = [];

function acquireDbConnection(span, traceId) {
  return new Promise((resolve, reject) => {
    if (activeConnections < config.DB_POOL_MAX) {
      activeConnections++;
      return resolve({
        id: `conn_${Math.random().toString(36).substring(7)}`,
        release: () => {
          activeConnections = Math.max(0, activeConnections - 1);
          if (waitQueue.length > 0) {
            const next = waitQueue.shift();
            activeConnections++;
            next.resolve({
              id: `conn_${Math.random().toString(36).substring(7)}`,
              release: () => {
                activeConnections = Math.max(0, activeConnections - 1);
              }
            });
          }
        }
      });
    }

    // Neu Pool day, dua vao hang doi voi timeout
    const timeoutHandle = setTimeout(() => {
      const idx = waitQueue.findIndex(item => item.id === waitItem.id);
      if (idx !== -1) waitQueue.splice(idx, 1);

      const errMsg = `Timeout (${config.DB_TIMEOUT_MS}ms) waiting for database connection. Pool capacity reached: active=${activeConnections}, max=${config.DB_POOL_MAX}, waiting=${waitQueue.length + 1}`;
      const poolErr = new Error(errMsg);
      poolErr.name = 'ConnectionPoolExhaustedError';

      // Ghi log ERROR chuan JSON ra file
      const logEntry = JSON.stringify({
        timestamp: new Date().toISOString(),
        level: 'error',
        service: 'payment-service',
        trace_id: traceId,
        error_name: 'ConnectionPoolExhaustedError',
        message: errMsg,
        stack: poolErr.stack,
        pool_status: { active: activeConnections, max: config.DB_POOL_MAX, waiting: waitQueue.length }
      });
      fs.appendFileSync('/var/log/apps/payment-service.log', logEntry + '\n');

      reject(poolErr);
    }, config.DB_TIMEOUT_MS);

    const waitItem = {
      id: Math.random().toString(36).substring(7),
      resolve: (conn) => {
        clearTimeout(timeoutHandle);
        resolve(conn);
      }
    };
    waitQueue.push(waitItem);
  });
}

app.get('/health', (req, res) => {
  config = loadConfig();
  res.json({
    status: 'UP',
    service: 'payment-service',
    pool: { active: activeConnections, max: config.DB_POOL_MAX, queue: waitQueue.length }
  });
});

app.post('/api/pay', async (req, res) => {
  config = loadConfig();
  const parentCtx = propagation.extract(context.active(), req.headers);
  const paymentSpan = tracer.startSpan('payment_checkout', {}, parentCtx);
  const activeCtx = trace.setSpan(parentCtx, paymentSpan);
  const traceId = paymentSpan.spanContext().traceId;

  paymentSpan.setAttribute('payment.service', 'payment-service');
  paymentSpan.setAttribute('payment.amount', req.body.amount || 100);

  const acquireSpan = tracer.startSpan('db_acquire_connection', {}, activeCtx);
  let conn = null;

  try {
    conn = await acquireDbConnection(acquireSpan, traceId);
    acquireSpan.setStatus({ code: SpanStatusCode.OK });
    acquireSpan.end();

    // Mo phong query DB xu ly giao dich
    const querySpan = tracer.startSpan('db_execute_payment_transaction', {}, activeCtx);
    await new Promise(r => setTimeout(r, config.DB_QUERY_LATENCY_MS || 450));
    querySpan.setStatus({ code: SpanStatusCode.OK });
    querySpan.end();

    paymentSpan.setStatus({ code: SpanStatusCode.OK });
    paymentSpan.end();

    conn.release();

    const infoLog = JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'info',
      service: 'payment-service',
      trace_id: traceId,
      message: 'Payment transaction processed successfully',
      amount: req.body.amount || 100
    });
    fs.appendFileSync('/var/log/apps/payment-service.log', infoLog + '\n');

    return res.status(200).json({ status: 'SUCCESS', transaction_id: 'txn_' + Date.now() });
  } catch (err) {
    acquireSpan.recordException(err);
    acquireSpan.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
    acquireSpan.end();

    paymentSpan.recordException(err);
    paymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
    paymentSpan.end();

    if (conn) conn.release();

    return res.status(503).json({
      error: 'Database connection pool exhausted',
      code: 'ERR_DB_POOL_EXHAUSTED',
      details: err.message
    });
  }
});

const PORT = 3002;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Payment Service listening on port ${PORT}`);
});
EOF

# 6. Trien khai Order Service
cat << 'EOF' > /root/incident-lab/order-service.js
const express = require('express');
const http = require('http');
const fs = require('fs');
const { initTracer, trace, context, propagation, SpanStatusCode } = require('./tracer');

const { tracer } = initTracer('order-service');
const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-service' });
});

app.post('/api/checkout', async (req, res) => {
  const orderSpan = tracer.startSpan('order_checkout');
  const activeCtx = trace.setSpan(context.active(), orderSpan);
  const traceId = orderSpan.spanContext().traceId;
  const orderId = 'ord_' + Date.now();

  orderSpan.setAttribute('order.id', orderId);
  orderSpan.setAttribute('order.item', req.body.item || 'Generic Item');

  // Goi sang Payment Service voi Context Propagation
  const callPaymentSpan = tracer.startSpan('call_payment_service', {}, activeCtx);
  const outgoingHeaders = { 'Content-Type': 'application/json' };
  propagation.inject(activeCtx, outgoingHeaders);

  const payload = JSON.stringify({ order_id: orderId, amount: req.body.amount || 150 });

  const clientReq = http.request('http://127.0.0.1:3002/api/pay', {
    method: 'POST',
    headers: {
      ...outgoingHeaders,
      'Content-Length': Buffer.byteLength(payload)
    },
    timeout: 3000
  }, (paymentRes) => {
    let rawData = '';
    paymentRes.on('data', chunk => { rawData += chunk; });
    paymentRes.on('end', () => {
      if (paymentRes.statusCode >= 200 && paymentRes.statusCode < 300) {
        callPaymentSpan.setStatus({ code: SpanStatusCode.OK });
        callPaymentSpan.end();
        orderSpan.setStatus({ code: SpanStatusCode.OK });
        orderSpan.end();

        const successLog = JSON.stringify({
          timestamp: new Date().toISOString(),
          level: 'info',
          service: 'order-service',
          trace_id: traceId,
          order_id: orderId,
          message: 'Order completed successfully'
        });
        fs.appendFileSync('/var/log/apps/order-service.log', successLog + '\n');

        return res.status(200).json({ status: 'COMPLETED', order_id: orderId });
      } else {
        const errorMsg = `Payment failed with status ${paymentRes.statusCode}: ${rawData}`;
        const err = new Error(errorMsg);
        callPaymentSpan.recordException(err);
        callPaymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: errorMsg });
        callPaymentSpan.end();

        orderSpan.recordException(err);
        orderSpan.setStatus({ code: SpanStatusCode.ERROR, message: errorMsg });
        orderSpan.end();

        const errLog = JSON.stringify({
          timestamp: new Date().toISOString(),
          level: 'error',
          service: 'order-service',
          trace_id: traceId,
          order_id: orderId,
          message: `Downstream payment failure: HTTP ${paymentRes.statusCode}`,
          response: rawData
        });
        fs.appendFileSync('/var/log/apps/order-service.log', errLog + '\n');

        return res.status(504).json({
          error: 'Gateway Timeout / Downstream Service Failure',
          code: 'ORDER_PROCESSING_FAILED',
          trace_id: traceId
        });
      }
    });
  });

  clientReq.on('timeout', () => {
    clientReq.destroy();
    const timeoutErr = new Error('HTTP request to payment-service timed out after 3000ms');
    callPaymentSpan.recordException(timeoutErr);
    callPaymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: timeoutErr.message });
    callPaymentSpan.end();

    orderSpan.recordException(timeoutErr);
    orderSpan.setStatus({ code: SpanStatusCode.ERROR, message: timeoutErr.message });
    orderSpan.end();

    const errLog = JSON.stringify({
      timestamp: new Date().toISOString(),
      level: 'error',
      service: 'order-service',
      trace_id: traceId,
      order_id: orderId,
      message: timeoutErr.message
    });
    fs.appendFileSync('/var/log/apps/order-service.log', errLog + '\n');

    return res.status(504).json({
      error: 'Gateway Timeout: downstream payment service timeout',
      code: 'GATEWAY_TIMEOUT',
      trace_id: traceId
    });
  });

  clientReq.on('error', (e) => {
    callPaymentSpan.recordException(e);
    callPaymentSpan.setStatus({ code: SpanStatusCode.ERROR, message: e.message });
    callPaymentSpan.end();

    orderSpan.recordException(e);
    orderSpan.setStatus({ code: SpanStatusCode.ERROR, message: e.message });
    orderSpan.end();

    return res.status(502).json({ error: 'Bad Gateway: cannot connect to payment service' });
  });

  clientReq.write(payload);
  clientReq.end();
});

const PORT = 3001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order Service listening on port ${PORT}`);
});
EOF

# 7. Cau hinh Nginx Reverse Proxy
cat << 'EOF' > /root/incident-lab/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  custom  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" rt=$request_time';

    access_log  /var/log/nginx/access.log  custom;
    access_log  /var/log/apps/nginx-access.log custom;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location /api/checkout {
            proxy_pass http://127.0.0.1:3001/api/checkout;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_read_timeout 5s;
        }

        location /health {
            return 200 '{"status":"UP","gateway":"nginx"}\n';
            add_header Content-Type application/json;
        }
    }
}
EOF

# 8. Cau hinh Fluent Bit Parser va Pipeline day log ve Loki
cat << 'EOF' > /root/incident-lab/parsers.conf
[PARSER]
    Name        json_parser
    Format      json
    Time_Key    timestamp
    Time_Format %Y-%m-%dT%H:%M:%S.%L%z

[PARSER]
    Name        nginx_parser
    Format      regex
    Regex       ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +(?<protocol>\S+))?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")? rt=(?<request_time>[^ ]*)$
EOF

cat << 'EOF' > /root/incident-lab/fluent-bit.conf
[SERVICE]
    Flush         1
    Log_Level     error
    Parsers_File  /fluent-bit/etc/parsers.conf

[INPUT]
    Name              tail
    Path              /var/log/apps/payment-service.log
    Tag               app.payment
    Parser            json_parser
    Read_from_Head    On
    Refresh_Interval  1

[INPUT]
    Name              tail
    Path              /var/log/apps/order-service.log
    Tag               app.orders
    Parser            json_parser
    Read_from_Head    On
    Refresh_Interval  1

[INPUT]
    Name              tail
    Path              /var/log/apps/nginx-access.log
    Tag               web.nginx
    Parser            nginx_parser
    Read_from_Head    On
    Refresh_Interval  1

[OUTPUT]
    Name                   loki
    Match                  app.payment
    Host                   127.0.0.1
    Port                   3100
    Labels                 service=payment-service, type=application
    Auto_Kubernetes_Labels off

[OUTPUT]
    Name                   loki
    Match                  app.orders
    Host                   127.0.0.1
    Port                   3100
    Labels                 service=order-service, type=application
    Auto_Kubernetes_Labels off

[OUTPUT]
    Name                   loki
    Match                  web.nginx
    Host                   127.0.0.1
    Port                   3100
    Labels                 service=nginx-gateway, type=access
    Auto_Kubernetes_Labels off
EOF

# 9. Khoi dong cac Docker Container
docker rm -f jaeger loki nginx-gateway fluent-bit > /dev/null 2>&1 || true

docker run -d --name jaeger \
  -p 16686:16686 -p 4318:4318 \
  jaegertracing/all-in-one:1.53 > /dev/null 2>&1

docker run -d --name loki \
  -p 3100:3100 \
  grafana/loki:2.9.2 > /dev/null 2>&1

# Cho Jaeger va Loki san sang
sleep 3

# Khoi dong Nginx Gateway
docker run -d --name nginx-gateway \
  --network host \
  -v /root/incident-lab/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /var/log/apps:/var/log/apps \
  -v /var/log/apps:/var/log/nginx \
  nginx:alpine > /dev/null 2>&1

# Khoi dong Fluent Bit
docker run -d --name fluent-bit \
  --network host \
  -v /root/incident-lab/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro \
  -v /root/incident-lab/parsers.conf:/fluent-bit/etc/parsers.conf:ro \
  -v /var/log/apps:/var/log/apps:ro \
  fluent/fluent-bit:2.2 > /dev/null 2>&1

# 10. Khoi chay 2 dich vu Backend
pkill -f "order-service.js" > /dev/null 2>&1 || true
pkill -f "payment-service.js" > /dev/null 2>&1 || true

nohup node /root/incident-lab/payment-service.js > /var/log/apps/payment-service-stdout.log 2>&1 &
nohup node /root/incident-lab/order-service.js > /var/log/apps/order-service-stdout.log 2>&1 &

sleep 2

# Tao script restart tien dung cho hoc vien khi hotfix
cat << 'EOF' > /root/incident-lab/restart-payment-service.sh
#!/bin/bash
pkill -f "payment-service.js" > /dev/null 2>&1 || true
sleep 1
nohup node /root/incident-lab/payment-service.js > /var/log/apps/payment-service-stdout.log 2>&1 &
echo "[OK] Payment Service da duoc khoi dong lai voi cau hinh moi!"
EOF
chmod +x /root/incident-lab/restart-payment-service.sh

# 11. Khoi dong Traffic Generator ngam tao "Hien truong vu an"
cat << 'EOF' > /root/incident-lab/traffic-generator.sh
#!/bin/bash
while true; do
  for i in {1..3}; do
    curl -s -X POST http://localhost/api/checkout \
      -H "Content-Type: application/json" \
      -d '{"item":"iPhone 16 Pro Max","amount":1599}' > /dev/null 2>&1 &
  done
  sleep 0.8
done
EOF
chmod +x /root/incident-lab/traffic-generator.sh

nohup /root/incident-lab/traffic-generator.sh > /dev/null 2>&1 &

touch /tmp/background-finished
