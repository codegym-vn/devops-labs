#!/bin/bash
echo "Dang don dep moi truong Lab 45..."
docker rm -f grafana prometheus 2>/dev/null || true
pkill -f "python3 /root/load-monitoring-lab/app/server.py" 2>/dev/null || true
rm -rf /root/load-monitoring-lab
rm -f /tmp/background-finished
echo "Da don dep hoan tat."
