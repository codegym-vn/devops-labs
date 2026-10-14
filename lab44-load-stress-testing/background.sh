#!/bin/bash

trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/load-test-lab/scripts
mkdir -p /root/load-test-lab/reports
mkdir -p /root/load-test-lab/app
cd /root/load-test-lab

# 1. Cai dat k6 cong cu kiem thu tai
if ! command -v k6 &> /dev/null; then
  # Thu tai binary static
  curl -sSL https://github.com/grafana/k6/releases/download/v0.54.0/k6-v0.54.0-linux-amd64.tar.gz -o /tmp/k6.tar.gz 2>/dev/null && \
    tar -xzf /tmp/k6.tar.gz -C /tmp && \
    mv /tmp/k6-v0.54.0-linux-amd64/k6 /usr/local/bin/k6 && \
    chmod +x /usr/local/bin/k6 || true
fi

# Fallback wrapper container neu chua co binary
if ! command -v k6 &> /dev/null; then
  docker pull grafana/k6:latest >/dev/null 2>&1 || true
  cat << 'WRAPPER' > /usr/local/bin/k6
#!/bin/bash
docker run --rm -i --network host -v "$(pwd):$(pwd)" -w "$(pwd)" grafana/k6:latest "$@"
WRAPPER
  chmod +x /usr/local/bin/k6
fi

# 2. Xay dung Mock Target API (Ecommerce Service)
cat << 'EOF' > /root/load-test-lab/app/server.py
import http.server
import socketserver
import time
import random
import threading
import json

class TargetAppState:
    def __init__(self):
        self.lock = threading.Lock()
        self.active_requests = 0
        self.total_requests = 0
        self.error_count = 0

    def increment(self):
        with self.lock:
            self.active_requests += 1
            self.total_requests += 1
            return self.active_requests

    def decrement(self):
        with self.lock:
            self.active_requests = max(0, self.active_requests - 1)

    def record_error(self):
        with self.lock:
            self.error_count += 1

app_state = TargetAppState()

class LoadTestHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Tat log console mac dinh de giam thieu I/O overhead khi tai cao
        return

    def do_GET(self):
        current_concurrency = app_state.increment()
        try:
            if self.path == '/health':
                content = json.dumps({"status": "UP", "active_workers": current_concurrency}).encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(content)))
                self.end_headers()
                self.wfile.write(content)

            elif self.path == '/api/products':
                # Base latency 15ms + bien thien theo concurrency
                delay = 0.015 + (current_concurrency * 0.002)
                time.sleep(delay)

                products = [
                    {"id": 101, "name": "Cloud Server Node", "price": 45.0},
                    {"id": 102, "name": "Load Balancer VIP", "price": 20.0},
                    {"id": 103, "name": "Managed Redis Cluster", "price": 80.0}
                ]
                content = json.dumps(products).encode('utf-8')
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
        current_concurrency = app_state.increment()
        try:
            if self.path == '/api/orders':
                content_len = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_len) if content_len > 0 else b'{}'

                # Mo phong tinh toan logic nghiep vu:
                # Concurrency <= 30: he thong dap ung tot (25ms - 40ms)
                # Concurrency 31 - 70: hang doi xu ly tang, latency 80ms - 200ms
                # Concurrency > 70: qua tai he thong (Breaking Point), latency 400ms - 800ms va xuat hien loi 503
                if current_concurrency <= 30:
                    delay = 0.025 + random.uniform(0.005, 0.015)
                    time.sleep(delay)
                    status_code = 201
                    resp_body = {"order_id": f"ORD-{random.randint(10000, 99999)}", "status": "CONFIRMED"}

                elif current_concurrency <= 70:
                    delay = 0.080 + (current_concurrency * 0.003) + random.uniform(0.01, 0.03)
                    time.sleep(delay)
                    status_code = 201
                    resp_body = {"order_id": f"ORD-{random.randint(10000, 99999)}", "status": "CONFIRMED"}

                else:
                    # Diem gay: hang doi tran, ty le tra loi 503 la 40%
                    delay = 0.350 + random.uniform(0.1, 0.4)
                    time.sleep(delay)
                    if random.random() < 0.40:
                        app_state.record_error()
                        status_code = 503
                        resp_body = {"error": "SERVICE_UNAVAILABLE", "message": "Worker thread pool exhausted"}
                    else:
                        status_code = 201
                        resp_body = {"order_id": f"ORD-{random.randint(10000, 99999)}", "status": "CONFIRMED_DEGRADED"}

                content = json.dumps(resp_body).encode('utf-8')
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
    server = ThreadingHTTPServer(('0.0.0.0', 8080), LoadTestHandler)
    server.serve_forever()
EOF

# 3. Khoi chay ung dung muc tieu
pkill -f "python3 /root/load-test-lab/app/server.py" 2>/dev/null || true
nohup python3 /root/load-test-lab/app/server.py > /root/load-test-lab/app/server.log 2>&1 &

# Cho ung dung khoi dong
for i in {1..15}; do
  if curl -s http://localhost:8080/health | grep -q "UP"; then
    break
  fi
  sleep 1
done

# Tao mau kịch bản baseline khoi dau
cat << 'EOF' > /root/load-test-lab/scripts/smoke-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  duration: '5s',
};

export default function () {
  const res = http.get('http://localhost:8080/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
EOF

touch /tmp/background-finished
