#!/bin/bash
echo "Dang don dep moi truong Lab 44..."
pkill -f "python3 /root/load-test-lab/app/server.py" 2>/dev/null || true
rm -rf /root/load-test-lab
rm -f /tmp/background-finished
echo "Da don dep hoan tat."
