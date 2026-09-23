#!/bin/bash

# Cap nhat va cai dat cac cong cu can thiet
apt-get update -y > /dev/null 2>&1
apt-get install -y bc jq stress-ng curl python3 > /dev/null 2>&1

# Chuan bi file log canh bao
touch /var/log/alerts.log
chmod 666 /var/log/alerts.log

# Tao Local Webhook Receiver bang Python tren port 9090
cat << 'EOF' > /usr/local/bin/mock_alert_receiver.py
import http.server
import socketserver
import datetime
import json

PORT = 9090
LOG_FILE = "/var/log/alerts.log"

class AlertHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Local Alert Receiver is running\n")

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        post_data = self.rfile.read(content_length).decode("utf-8")
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] Alert received: {post_data}\n"
        with open(LOG_FILE, "a") as f:
            f.write(log_entry)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"status": "received", "timestamp": timestamp}).encode("utf-8"))

    def log_message(self, format, *args):
        return

with socketserver.TCPServer(("0.0.0.0", PORT), AlertHandler) as httpd:
    httpd.serve_forever()
EOF

# Tao systemd service de quan ly Alert Receiver
cat << 'EOF' > /etc/systemd/system/alert-receiver.service
[Unit]
Description=Local Alert Webhook Receiver
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/mock_alert_receiver.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now alert-receiver.service > /dev/null 2>&1

# Danh dau moi truong da san sang
touch /tmp/.lab_ready
