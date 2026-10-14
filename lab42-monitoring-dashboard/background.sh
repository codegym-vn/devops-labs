#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/grafana-lab/provisioning/datasources
mkdir -p /root/grafana-lab/provisioning/dashboards
mkdir -p /root/grafana-lab/dashboards
mkdir -p /root/grafana-lab/app
cd /root/grafana-lab

# 1. Khoi tao script Python 3 mock server doc lap, khoi dong ngay lap tuc
cat << 'EOF' > /root/grafana-lab/app/server.py
import http.server
import socketserver
import time
import random
import threading
import json

class MetricState:
    def __init__(self):
        self.lock = threading.Lock()
        self.products_get_200 = 45
        self.products_get_500 = 2
        self.orders_post_201 = 38
        self.orders_post_400 = 5
        self.orders_post_500 = 3
        self.users_get_200 = 50
        self.active_users = 85
        self.bucket_bounds = [0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]
        self.buckets = {0.02: 25, 0.05: 60, 0.1: 95, 0.2: 125, 0.5: 138, 1.0: 142, 2.0: 143}
        self.bucket_inf = 143
        self.duration_sum = 18.5
        self.duration_count = 143

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
        delta = random.randint(-4, 4)
        metrics.active_users = max(20, min(150, metrics.active_users + delta))
        dur = random.uniform(0.02, 0.25)
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
            time.sleep(random.uniform(0.02, 0.05))
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

# 2. Khoi tao tep cau hinh prometheus.yml
cat << 'EOF' > /root/grafana-lab/prometheus.yml
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

# 3. Don dep cac container va process cu
docker rm -f node-exporter prometheus grafana > /dev/null 2>&1 || true
pkill -f "server.py" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 4. Khoi chay Mock API
nohup python3 /root/grafana-lab/app/server.py > /root/grafana-lab/app.log 2>&1 &
sleep 1

# 5. Khoi chay Node Exporter
docker run -d --name node-exporter \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.0 \
  --path.rootfs=/host > /dev/null 2>&1

# 6. Khoi chay Prometheus Server
docker run -d --name prometheus \
  --network host \
  -v /root/grafana-lab/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.51.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle > /dev/null 2>&1

# 7. Khoi dong Traffic Generator ngam
cat << 'EOF' > /root/grafana-lab/traffic-generator.sh
#!/bin/bash
while true; do
  curl -s http://localhost:8080/api/products > /dev/null 2>&1 &
  curl -s -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"amount":100}' > /dev/null 2>&1 &
  curl -s http://localhost:8080/api/users > /dev/null 2>&1 &
  sleep 0.5
done
EOF
chmod +x /root/grafana-lab/traffic-generator.sh
nohup /root/grafana-lab/traffic-generator.sh > /dev/null 2>&1 &

# 8. Khoi tao truoc tep Datasource va Dashboard Provider de Grafana dang ky ngay tu luc boot
cat << 'EOF' > /root/grafana-lab/provisioning/datasources/prometheus-datasource.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      timeInterval: 2s
EOF

cat << 'EOF' > /root/grafana-lab/provisioning/dashboards/dashboard-provider.yml
apiVersion: 1

providers:
  - name: 'infrastructure-dashboards'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF

chmod -R 777 /root/grafana-lab/provisioning /root/grafana-lab/dashboards


# 9. Khoi chay Grafana Server (voi cac bien moi truong cho phep truy cap admin khong can login phuc tap)
docker run -d --name grafana \
  --network host \
  -e "GF_SECURITY_ADMIN_USER=admin" \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
  -e "GF_AUTH_ANONYMOUS_ENABLED=true" \
  -e "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin" \
  -e "GF_USERS_ALLOW_SIGN_UP=false" \
  -v /root/grafana-lab/provisioning:/etc/grafana/provisioning \
  -v /root/grafana-lab/dashboards:/var/lib/grafana/dashboards \
  grafana/grafana:10.4.1 > /dev/null 2>&1


# Cho Grafana khoi dong san sang tren cong 3000
for i in {1..30}; do
  if curl -s http://localhost:3000/api/health | grep -q '"database": "ok"'; then
    break
  fi
  sleep 1
done

touch /tmp/background-finished
