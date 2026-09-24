#!/bin/bash

# Tao thu muc lam viec
mkdir -p /root/app /root/logs

# File mau bien moi truong cho Step 1
cat << 'EOF' > /root/app/.env.app
APP_ENV=production
APP_PORT=8080
LOG_LEVEL=INFO
MAX_CONNECTIONS=100
EOF

# Script kiem thu cap phat bo nho (Memory Eater) cho Step 2
cat << 'EOF' > /root/app/oom_test.py
import time
import sys

print("[START] Bat dau cap phat bo nho...", flush=True)
data = []
chunk_mb = 20

try:
    for i in range(1, 20):
        # Cap phat 20MB moi lan lap
        data.append(b"x" * (chunk_mb * 1024 * 1024))
        print(f"[ALLOCATED] Da cap phat {i * chunk_mb} MB RAM...", flush=True)
        time.sleep(0.5)
except MemoryError:
    print("[ERROR] MemoryError: Khong the cap phat them bo nho!", flush=True)
    sys.exit(1)

print("[DONE] Hoan tat cap phat.", flush=True)
EOF

# Script ung dung Web xu ly Graceful Shutdown cho Step 3
cat << 'EOF' > /root/app/server.py
import http.server
import socketserver
import signal
import sys
import time
import json
import threading

PORT = 8080
is_shutting_down = False
active_requests = 0
lock = threading.Lock()

def log_event(level, message, **kwargs):
    entry = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "level": level,
        "message": message
    }
    entry.update(kwargs)
    print(json.dumps(entry), flush=True)

class GracefulHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        global active_requests, is_shutting_down
        with lock:
            if is_shutting_down:
                self.send_response(503)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "rejecting", "error": "Server is shutting down"}\n')
                return
            active_requests += 1

        log_event("INFO", "Nhan request moi", path=self.path, in_flight=active_requests)

        # Neu la request gia lap xu ly lau
        if self.path == "/work":
            # Gia lap xu ly ton 3 giay
            time.sleep(3)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "success", "message": "Work completed successfully"}\n')
        else:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "ok", "service": "order-service"}\n')

        with lock:
            active_requests -= 1
        log_event("INFO", "Hoan tat xu ly request", path=self.path, in_flight=active_requests)

    def log_message(self, format, *args):
        # Vo hieu hoa log mac dinh cua SimpleHTTPRequestHandler de dung JSON structured log
        return

def handle_sigterm(signum, frame):
    global is_shutting_down
    log_event("WARN", "Nhan tin hieu SIGTERM (15). Bat dau quy trinh Graceful Shutdown...")
    is_shutting_down = True

    # Cho den khi tat ca in-flight requests hoan tat (Connection Draining)
    max_wait = 10
    start = time.time()
    while active_requests > 0 and (time.time() - start) < max_wait:
        log_event("INFO", "Dang cho requests hoan tat...", remaining=active_requests)
        time.sleep(0.5)

    log_event("INFO", "Tat ca ket noi da duoc giai phong. Dong HTTP server...")
    # Dong server trong thread rieng de khong bi block signal
    threading.Thread(target=httpd.shutdown).start()

# Dang ky signal handler
signal.signal(signal.SIGTERM, handle_sigterm)
signal.signal(signal.SIGINT, handle_sigterm)

class ReusableServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    allow_reuse_address = True

httpd = ReusableServer(("", PORT), GracefulHandler)
log_event("INFO", f"Server khoi dong thanh cong tren cong {PORT}", pid=1)

try:
    httpd.serve_forever()
finally:
    httpd.server_close()
    log_event("INFO", "Server da tat hoan toan va an toan (Graceful exit). Exit code: 0")
    sys.exit(0)
EOF

# Tai truoc alpine image nhe trong background
docker pull alpine:3.19 > /dev/null 2>&1 &
docker pull python:3.11-alpine > /dev/null 2>&1 &

# Danh dau he thong san sang
touch /tmp/.lab_ready
