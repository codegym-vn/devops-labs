#!/bin/bash

trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/alerting-lab/rules
mkdir -p /root/alerting-lab/app
cd /root/alerting-lab

# 1. Khoi tao App Mock API voi ho tro Fault Injection de mo phong su co
cat << 'EOF' > /root/alerting-lab/app/server.py
import http.server
import socketserver
import time
import random
import threading
import json

class MockAppState:
    def __init__(self):
        self.lock = threading.Lock()
        self.error_mode = False
        self.products_get_200 = 50
        self.products_get_500 = 1
        self.orders_post_201 = 40
        self.orders_post_400 = 2
        self.orders_post_500 = 1
        self.users_get_200 = 60
        self.active_users = 85

    def record_request(self, method, path, status):
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
                "# HELP active_users_total Current active connected users",
                "# TYPE active_users_total gauge",
                f"active_users_total {self.active_users}",
                ""
            ]
            return "\n".join(lines)

app_state = MockAppState()

class AppHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
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
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/api/products':
            app_state.record_request('GET', '/api/products', 200)
            content = json.dumps([{"id": 1, "name": "Laptop"}]).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/api/users':
            app_state.record_request('GET', '/api/users', 200)
            content = json.dumps({"users": 120}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/simulate/errors':
            app_state.error_mode = True
            content = json.dumps({"message": "ERROR MODE ACTIVATED (High 500 Error Rate)"}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/simulate/recover':
            app_state.error_mode = False
            content = json.dumps({"message": "RECOVERED (Normal Operations Restored)"}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(content)
        elif self.path == '/api/orders':
            if app_state.error_mode:
                # 85% probability of 500 error when simulated
                if random.random() < 0.85:
                    app_state.record_request('POST', '/api/orders', 500)
                    content = json.dumps({"error": "Payment Gateway Timeout", "code": 500}).encode('utf-8')
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(content)
                    return
            app_state.record_request('POST', '/api/orders', 201)
            content = json.dumps({"status": "ORDER_CREATED", "id": "ord_123"}).encode('utf-8')
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = socketserver.TCPServer(('0.0.0.0', 8080), AppHandler)
    server.allow_reuse_address = True
    server.serve_forever()
EOF

# 2. Khoi tao Webhook Receiver gia lap tren cong 5001 de ghi nhan Alertmanager payload
cat << 'EOF' > /root/alerting-lab/webhook_receiver.py
import http.server
import socketserver
import json
import time

LOG_FILE = '/root/alerting-lab/webhook.log'
LATEST_ALERT_FILE = '/root/alerting-lab/latest-alert.json'

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        try:
            payload = json.loads(body)
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            status = payload.get('status', 'unknown')
            alerts = payload.get('alerts', [])
            
            with open(LOG_FILE, 'a') as f:
                f.write(f"[{timestamp}] RECEIVED WEBHOOK ALERT (Status: {status}, Count: {len(alerts)})\n")
                for a in alerts:
                    f.write(f"  - Alert: {a.get('labels', {}).get('alertname')} | Severity: {a.get('labels', {}).get('severity')} | Status: {a.get('status')}\n")
                    f.write(f"    Summary: {a.get('annotations', {}).get('summary')}\n")
            
            with open(LATEST_ALERT_FILE, 'w') as f:
                json.dump(payload, f, indent=2)
                
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"received"}')
        except Exception as e:
            self.send_response(400)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = socketserver.TCPServer(('0.0.0.0', 5001), WebhookHandler)
    server.allow_reuse_address = True
    server.serve_forever()
EOF

# 3. Don dep cac container va process cu
docker rm -f node-exporter prometheus alertmanager > /dev/null 2>&1 || true
pkill -f "server.py" > /dev/null 2>&1 || true
pkill -f "webhook_receiver.py" > /dev/null 2>&1 || true
pkill -f "traffic-generator.sh" > /dev/null 2>&1 || true

# 4. Khoi chay App API va Webhook Receiver
nohup python3 /root/alerting-lab/app/server.py > /root/alerting-lab/app.log 2>&1 &
nohup python3 /root/alerting-lab/webhook_receiver.py > /dev/null 2>&1 &
sleep 1

# 5. Khoi chay Node Exporter
docker run -d --name node-exporter \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.0 \
  --path.rootfs=/host > /dev/null 2>&1

# 6. Khoi tao tep cau hinh ban dau alertmanager.yml
cat << 'EOF' > /root/alerting-lab/alertmanager.yml
global:
  resolve_timeout: 1m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 5s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'mock-webhook'

receivers:
  - name: 'mock-webhook'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true
EOF

# 7. Khoi chay Alertmanager
docker run -d --name alertmanager \
  --network host \
  -v /root/alerting-lab/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  prom/alertmanager:v0.27.0 \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --web.listen-address="0.0.0.0:9093" > /dev/null 2>&1

# 8. Khoi tao tep cau hinh prometheus.yml
cat << 'EOF' > /root/alerting-lab/prometheus.yml
global:
  scrape_interval: 2s
  evaluation_interval: 2s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

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

# 9. Khoi chay Prometheus Server
docker run -d --name prometheus \
  --network host \
  -v /root/alerting-lab:/etc/prometheus \
  prom/prometheus:v2.51.0 \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.enable-lifecycle > /dev/null 2>&1

# 10. Tao Wrapper Scripts cho promtool va amtool tren host
cat << 'EOF' > /usr/local/bin/promtool
#!/bin/bash
docker exec -i prometheus promtool "$@"
EOF
chmod +x /usr/local/bin/promtool

cat << 'EOF' > /usr/local/bin/amtool
#!/bin/bash
docker exec -i alertmanager amtool --alertmanager.url=http://localhost:9093 "$@"
EOF
chmod +x /usr/local/bin/amtool

# 11. Khoi dong Traffic Generator ngam
cat << 'EOF' > /root/alerting-lab/traffic-generator.sh
#!/bin/bash
while true; do
  curl -s http://localhost:8080/api/products > /dev/null 2>&1 &
  curl -s -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"amount":100}' > /dev/null 2>&1 &
  curl -s http://localhost:8080/api/users > /dev/null 2>&1 &
  sleep 0.5
done
EOF
chmod +x /root/alerting-lab/traffic-generator.sh
nohup /root/alerting-lab/traffic-generator.sh > /dev/null 2>&1 &

touch /tmp/background-finished
