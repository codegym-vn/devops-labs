#!/bin/bash
echo "Dang don dep moi truong Lab 47..."
docker rm -f nginx-proxy 2>/dev/null || true
pkill -f "python3 /root/infra-opt-lab/app/server.py" 2>/dev/null || true
rm -rf /root/infra-opt-lab
rm -f /usr/local/bin/nginx-reload
rm -f /tmp/background-finished
echo "Da don dep hoan tat."
