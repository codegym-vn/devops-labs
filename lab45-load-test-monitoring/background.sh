#!/bin/bash

trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/load-monitoring-lab/app
mkdir -p /root/load-monitoring-lab/prometheus
mkdir -p /root/load-monitoring-lab/grafana/provisioning/datasources
mkdir -p /root/load-monitoring-lab/grafana/provisioning/dashboards
mkdir -p /root/load-monitoring-lab/scripts
mkdir -p /root/load-monitoring-lab/reports
cd /root/load-monitoring-lab

# 1. Cai dat k6 cong cu kiem thu tai
if ! command -v k6 &> /dev/null; then
  curl -sSL https://github.com/grafana/k6/releases/download/v0.54.0/k6-v0.54.0-linux-amd64.tar.gz -o /tmp/k6.tar.gz 2>/dev/null && \
    tar -xzf /tmp/k6.tar.gz -C /tmp && \
    mv /tmp/k6-v0.54.0-linux-amd64/k6 /usr/local/bin/k6 && \
    chmod +x /usr/local/bin/k6 || true
fi

if ! command -v k6 &> /dev/null; then
  docker pull grafana/k6:latest >/dev/null 2>&1 || true
  cat << 'WRAPPER' > /usr/local/bin/k6
#!/bin/bash
docker run --rm -i --network host -v "$(pwd):$(pwd)" -w "$(pwd)" grafana/k6:latest "$@"
WRAPPER
  chmod +x /usr/local/bin/k6
fi

# 2. Xay dung Mock Target API phoi bay metrics Prometheus
cat << 'EOF' > /root/load-monitoring-lab/app/server.py
import http.server
import socketserver
import time
import random
import threading
import json

class TargetAppState:
    def __init__(self):
        self.lock = threading.Lock()
        self.active_connections = 0
        self.total_orders_201 = 120
        self.total_orders_503 = 0
        self.total_products_200 = 250
        self.duration_seconds_sum = 18.5
        self.duration_seconds_count = 370
        self.exhausted_count = 0

    def increment(self):
        with self.lock:
            self.active_connections += 1
            return self.active_connections

    def decrement(self):
        with self.lock:
            self.active_connections = max(0, self.active_connections - 1)

    def record_request(self, path, status, duration):
        with self.lock:
            self.duration_seconds_sum += duration
            self.duration_seconds_count += 1
            if path == '/api/products':
                self.total_products_200 += 1
            elif path == '/api/orders':
                if status == 201:
                    self.total_orders_201 += 1
                else:
                    self.total_orders_503 += 1
                    self.exhausted_count += 1

    def get_metrics_text(self):
        with self.lock:
            # CPU scale ty le theo active connections: 5% idle + 1.1% per connection, tran o 98%
            cpu_val = min(98.5, 5.0 + (self.active_connections * 1.15) + random.uniform(0.5, 2.5))
            lines = [
                "# HELP http_requests_total Total number of HTTP requests processed",
                "# TYPE http_requests_total counter",
                f'http_requests_total{{method="GET",path="/api/products",status="200"}} {self.total_products_200}',
                f'http_requests_total{{method="POST",path="/api/orders",status="201"}} {self.total_orders_201}',
                f'http_requests_total{{method="POST",path="/api/orders",status="503"}} {self.total_orders_503}',
                "",
                "# HELP http_request_duration_seconds Total duration in seconds",
                "# TYPE http_request_duration_seconds summary",
                f'http_request_duration_seconds_sum {self.duration_seconds_sum:.3f}',
                f'http_request_duration_seconds_count {self.duration_seconds_count}',
                "",
                "# HELP app_active_connections Current active client connections",
                "# TYPE app_active_connections gauge",
                f'app_active_connections {self.active_connections}',
                "",
                "# HELP app_cpu_usage_percent Current server CPU utilization percentage",
                "# TYPE app_cpu_usage_percent gauge",
                f'app_cpu_usage_percent {cpu_val:.1f}',
                "",
                "# HELP app_thread_pool_exhausted_total Total thread pool saturation incidents",
                "# TYPE app_thread_pool_exhausted_total counter",
                f'app_thread_pool_exhausted_total {self.exhausted_count}',
                ""
            ]
            return "\n".join(lines)

app_state = TargetAppState()

class LoadCorrelationHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        start_t = time.time()
        conn = app_state.increment()
        try:
            if self.path == '/metrics':
                content = app_state.get_metrics_text().encode('utf-8')
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
                delay = 0.015 + (conn * 0.002)
                time.sleep(delay)
                dur = time.time() - start_t
                app_state.record_request('/api/products', 200, dur)
                content = json.dumps([{"id": 1, "item": "Cloud Server"}]).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            else:
                self.send_response(404)
                self.end_headers()
        finally:
            app_state.decrement()

    def do_POST(self):
        start_t = time.time()
        conn = app_state.increment()
        try:
            if self.path == '/api/orders':
                content_len = int(self.headers.get('Content-Length', 0))
                if content_len > 0:
                    self.rfile.read(content_len)

                # Nguong chiu tai: conn <= 35 thi tot (20-40ms). conn 36-70 thi cham (80-200ms). conn > 70 thi nghen (>400ms + loi 503)
                if conn <= 35:
                    delay = 0.025 + random.uniform(0.005, 0.015)
                    time.sleep(delay)
                    status_code = 201
                    resp = {"status": "CONFIRMED"}
                elif conn <= 70:
                    delay = 0.080 + (conn * 0.003) + random.uniform(0.01, 0.03)
                    time.sleep(delay)
                    status_code = 201
                    resp = {"status": "CONFIRMED"}
                else:
                    delay = 0.350 + random.uniform(0.1, 0.3)
                    time.sleep(delay)
                    if random.random() < 0.45:
                        status_code = 503
                        resp = {"error": "SERVICE_UNAVAILABLE", "message": "Thread pool exhausted"}
                    else:
                        status_code = 201
                        resp = {"status": "CONFIRMED_DEGRADED"}

                dur = time.time() - start_t
                app_state.record_request('/api/orders', status_code, dur)
                content = json.dumps(resp).encode('utf-8')
                self.send_response(status_code)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            else:
                self.send_response(404)
                self.end_headers()
        finally:
            app_state.decrement()

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == '__main__':
    server = ThreadingHTTPServer(('0.0.0.0', 8080), LoadCorrelationHandler)
    server.serve_forever()
EOF

pkill -f "python3 /root/load-monitoring-lab/app/server.py" 2>/dev/null || true
nohup python3 /root/load-monitoring-lab/app/server.py > /root/load-monitoring-lab/app/server.log 2>&1 &

# 3. Cau hinh Prometheus Server voi scrape chu ky 2 giay
cat << 'EOF' > /root/load-monitoring-lab/prometheus/prometheus.yml
global:
  scrape_interval: 2s
  evaluation_interval: 2s

scrape_configs:
  - job_name: 'target-api'
    static_configs:
      - targets: ['localhost:8080']
        labels:
          app: 'ecommerce-api'
          env: 'production'

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

docker rm -f prometheus 2>/dev/null || true
docker run -d --name prometheus --network host \
  -v /root/load-monitoring-lab/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.45.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle \
  --web.enable-remote-write-receiver

# 4. Cau hinh Grafana Provisioning
cat << 'EOF' > /root/load-monitoring-lab/grafana/provisioning/datasources/datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    uid: prometheus
    isDefault: true
    editable: false
EOF

cat << 'EOF' > /root/load-monitoring-lab/grafana/provisioning/dashboards/provider.yml
apiVersion: 1
providers:
  - name: 'Load Test & Monitoring Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

cat << 'EOF' > /root/load-monitoring-lab/grafana/provisioning/dashboards/load-correlation.json
{
  "annotations": { "list": [] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "collapsed": false,
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 },
      "id": 100,
      "title": "OVERVIEW: CORRELATION BETWEEN LOAD & SYSTEM METRICS",
      "type": "row"
    },
    {
      "id": 1,
      "title": "Active Client Connections",
      "type": "stat",
      "gridPos": { "h": 6, "w": 6, "x": 0, "y": 1 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "app_active_connections", "refId": "A" }
      ],
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "orange", "value": 40 },
              { "color": "red", "value": 70 }
            ]
          },
          "unit": "short"
        }
      }
    },
    {
      "id": 2,
      "title": "Server CPU Saturation",
      "type": "gauge",
      "gridPos": { "h": 6, "w": 6, "x": 6, "y": 1 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "app_cpu_usage_percent", "refId": "A" }
      ],
      "fieldConfig": {
        "defaults": {
          "min": 0,
          "max": 100,
          "unit": "percent",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": null },
              { "color": "#EAB839", "value": 70 },
              { "color": "red", "value": 85 }
            ]
          }
        }
      }
    },
    {
      "id": 3,
      "title": "Throughput: Requests Per Second (RPS)",
      "type": "timeseries",
      "gridPos": { "h": 6, "w": 12, "x": 12, "y": 1 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "sum(rate(http_requests_total[10s])) by (path)", "legendFormat": "{{path}}", "refId": "A" }
      ],
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "lineInterpolation": "smooth" },
          "unit": "reqps"
        }
      }
    },
    {
      "id": 4,
      "title": "Average Response Latency (ms)",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 7 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "(sum(rate(http_request_duration_seconds_sum[10s])) / sum(rate(http_request_duration_seconds_count[10s]))) * 1000", "legendFormat": "Avg Latency", "refId": "A" }
      ],
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line", "fillOpacity": 15 },
          "unit": "ms"
        }
      }
    },
    {
      "id": 5,
      "title": "HTTP Error Rate (%) & Saturation Incidents",
      "type": "timeseries",
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 7 },
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "targets": [
        { "expr": "(sum(rate(http_requests_total{status=~\"5..\"}[10s])) / clamp_min(sum(rate(http_requests_total[10s])), 0.001)) * 100", "legendFormat": "HTTP 5xx Error %", "refId": "A" },
        { "expr": "increase(app_thread_pool_exhausted_total[1m])", "legendFormat": "Pool Exhausted Events", "refId": "B" }
      ],
      "fieldConfig": {
        "defaults": {
          "custom": { "drawStyle": "line" },
          "unit": "percent"
        }
      }
    }
  ],
  "refresh": "2s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["sre", "loadtest", "correlation"],
  "time": { "from": "now-5m", "to": "now" },
  "title": "Load Testing & System Saturation Correlation",
  "uid": "load-correlation"
}
EOF

docker rm -f grafana 2>/dev/null || true
docker run -d --name grafana --network host \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  -e "GF_AUTH_ANONYMOUS_ENABLED=true" \
  -e "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin" \
  -v /root/load-monitoring-lab/grafana/provisioning:/etc/grafana/provisioning \
  grafana/grafana:10.1.0

# 5. Tao cac kich ban kiem thu tai k6 san sang trong /root/load-monitoring-lab/scripts
cat << 'EOF' > /root/load-monitoring-lab/scripts/load-baseline.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 15,
  duration: '45s',
};

export default function () {
  http.get('http://localhost:8080/api/products');
  http.post('http://localhost:8080/api/orders', JSON.stringify({ item: 'Cloud Server', qty: 1 }), {
    headers: { 'Content-Type': 'application/json' },
  });
  sleep(0.1);
}
EOF

cat << 'EOF' > /root/load-monitoring-lab/scripts/load-spike.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 25 },  // Baseline an toan
    { duration: '20s', target: 85 },  // Ep tai vuot nguong Saturation
    { duration: '15s', target: 10 },  // Ha nhiet ve an toan
  ],
};

export default function () {
  http.get('http://localhost:8080/api/products');
  http.post('http://localhost:8080/api/orders', JSON.stringify({ item: 'Heavy Load Task', qty: 5 }), {
    headers: { 'Content-Type': 'application/json' },
  });
  sleep(0.04);
}
EOF

touch /tmp/background-finished
