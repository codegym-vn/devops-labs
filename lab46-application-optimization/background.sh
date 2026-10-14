#!/bin/bash

trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/app-opt-lab/app
mkdir -p /root/app-opt-lab/scripts
mkdir -p /root/app-opt-lab/reports
mkdir -p /root/app-opt-lab/config
cd /root/app-opt-lab

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
docker run --rm -i -u root --network host -v /root:/root -v "$(pwd):$(pwd)" -w "$(pwd)" grafana/k6:latest "$@"
WRAPPER
  chmod +x /usr/local/bin/k6
fi

# 2. Khoi chay Redis Cache Container
docker rm -f redis-cache 2>/dev/null || true
docker run -d --name redis-cache --network host redis:7-alpine >/dev/null 2>&1 || true

# 3. Tao tep cau hinh ung dung
cat << 'EOF' > /root/app-opt-lab/config/app.env
# Cau hinh toi uu hoa ung dung
PORT=8080
CACHE_ENABLED=false
CACHE_TTL_SECONDS=60
EOF

# 4. Khoi tao ma nguon ung dung Catalog Service
cat << 'EOF' > /root/app-opt-lab/app/server.py
import http.server
import socketserver
import time
import json
import os
import urllib.request

CONFIG_FILE = "/root/app-opt-lab/config/app.env"

def is_cache_enabled():
    if not os.path.exists(CONFIG_FILE):
        return False
    with open(CONFIG_FILE, 'r') as f:
        for line in f:
            if line.strip().startswith('CACHE_ENABLED'):
                parts = line.strip().split('=')
                if len(parts) == 2 and parts[1].strip().lower() == 'true':
                    return True
    return False

# In-memory cache fallback co TTL
local_cache = {
    "data": None,
    "expires_at": 0
}

def generate_catalog_data():
    # Mo phong truy van Database phuc tap va serialization nang (~140ms)
    time.sleep(0.14)
    items = []
    for i in range(1, 41):
        items.append({
            "id": i,
            "sku": f"SKU-{i:04d}",
            "name": f"Cloud Computing Node Type-{i}",
            "category": "Infrastructure",
            "price": 49.99 + (i * 2.5),
            "in_stock": True
        })
    return items

class CatalogHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        if self.path == '/health':
            cache_status = "ENABLED" if is_cache_enabled() else "DISABLED"
            resp = json.dumps({"status": "UP", "cache": cache_status}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)

        elif self.path == '/api/catalog':
            use_cache = is_cache_enabled()
            now = time.time()
            data = None

            if use_cache:
                # Kiem tra cache hit
                if local_cache["data"] is not None and now < local_cache["expires_at"]:
                    data = local_cache["data"]
                    cache_header = "HIT"
                else:
                    data = generate_catalog_data()
                    local_cache["data"] = data
                    local_cache["expires_at"] = now + 60.0
                    cache_header = "MISS"
            else:
                data = generate_catalog_data()
                cache_header = "BYPASS"

            resp = json.dumps({"source": cache_header, "items": data}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('X-Cache-Status', cache_header)
            self.send_header('Content-Length', str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        else:
            self.send_response(404)
            self.end_headers()

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == '__main__':
    server = ThreadingHTTPServer(('0.0.0.0', 8080), CatalogHandler)
    server.serve_forever()
EOF

pkill -f "python3 /root/app-opt-lab/app/server.py" 2>/dev/null || true
nohup python3 /root/app-opt-lab/app/server.py > /root/app-opt-lab/app/server.log 2>&1 &

# 5. Khoi tao bao cao danh gia ban dau (Diagnostic Report)
cat << 'EOF' > /root/app-opt-lab/reports/initial-report.json
{
  "audit_target": "CATALOG-API-SERVICE",
  "audit_date": "2026-10-14",
  "performance_diagnostics": {
    "detected_bottlenecks": [
      {
        "endpoint": "/api/catalog",
        "issue": "High database read latency & repeated un-cached JSON serialization",
        "avg_db_query_time_ms": 140,
        "impact": "CPU saturation and worker threads blocked waiting for simulated I/O"
      }
    ],
    "recommended_actions": [
      "Implement Cache-Aside pattern with Redis or In-Memory Layer",
      "Set Time-To-Live (TTL) to 60 seconds for catalog data",
      "Validate throughput and p95 latency improvement using k6"
    ]
  }
}
EOF

# 6. Tao san kịch bản benchmark k6 dung chung cho ca 2 pha Before va After
cat << 'EOF' > /root/app-opt-lab/scripts/benchmark.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 20,
  duration: '15s',
};

export default function () {
  const res = http.get('http://localhost:8080/api/catalog');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'has catalog items': (r) => r.body.includes('Cloud Computing Node'),
  });

  sleep(0.05);
}
EOF

touch /tmp/background-finished
