#!/bin/bash

trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/infra-opt-lab/nginx
mkdir -p /root/infra-opt-lab/sysctl
mkdir -p /root/infra-opt-lab/scripts
mkdir -p /root/infra-opt-lab/reports
mkdir -p /root/infra-opt-lab/app
cd /root/infra-opt-lab

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

# 2. Khoi tao Backend Service tai port 8080
cat << 'EOF' > /root/infra-opt-lab/app/server.py
import http.server
import socketserver
import json
import time

class BackendHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        return

    def do_GET(self):
        if self.path == '/health':
            resp = json.dumps({"status": "UP"}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        elif self.path == '/api/data':
            # Fast response 5ms
            time.sleep(0.005)
            resp = json.dumps({"server": "backend-node-1", "status": "OK"}).encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(resp)))
            self.end_headers()
            self.wfile.write(resp)
        else:
            self.send_response(404)
            self.end_headers()

class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == '__main__':
    server = ThreadingHTTPServer(('127.0.0.1', 8080), BackendHandler)
    server.serve_forever()
EOF

pkill -f "python3 /root/infra-opt-lab/app/server.py" 2>/dev/null || true
nohup python3 /root/infra-opt-lab/app/server.py > /root/infra-opt-lab/app/server.log 2>&1 &

# 3. Khoi tao cau hinh Nginx chua toi uu (Bottleneck ban dau)
cat << 'EOF' > /root/infra-opt-lab/nginx/nginx.conf
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    # Gioi han rat thap: chi 64 ket noi dong thoi tren moi worker
    worker_connections 64;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream backend_nodes {
        # Chua cau hinh keepalive: moi request mo mot ket noi TCP moi
        server 127.0.0.1:8080;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://backend_nodes;
            # Mac dinh dung HTTP 1.0 khong tai su dung ket noi
        }
    }
}
EOF

# Khoi chay Nginx container
docker rm -f nginx-proxy 2>/dev/null || true
docker run -d --name nginx-proxy --network host \
  -v /root/infra-opt-lab/nginx/nginx.conf:/etc/nginx/nginx.conf \
  nginx:alpine >/dev/null 2>&1 || true

# 4. Tao kịch bản test stress qua cong 80
cat << 'EOF' > /root/infra-opt-lab/scripts/stress-high.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 80,         // 80 VUs dong thoi vuot qua worker_connections 64 cua Nginx
  duration: '15s',
};

export default function () {
  const res = http.get('http://localhost:80/api/data');

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(0.01); // Cuong do cao
}
EOF

# Wrapper reload nginx cho hoc vien
cat << 'EOF' > /usr/local/bin/nginx-reload
#!/bin/bash
if docker ps | grep -q nginx-proxy; then
  docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload
  echo "Da nạp lại cấu hình Nginx thành công."
elif command -v nginx &>/dev/null; then
  nginx -t && nginx -s reload
  echo "Da nạp lại cấu hình Nginx thành công."
fi
EOF
chmod +x /usr/local/bin/nginx-reload

touch /tmp/background-finished
