#!/bin/bash
echo "Dang don dep moi truong Lab 46..."
docker rm -f redis-cache 2>/dev/null || true
pkill -f "python3 /root/app-opt-lab/app/server.py" 2>/dev/null || true
rm -rf /root/app-opt-lab
rm -f /tmp/background-finished
echo "Da don dep hoan tat."
