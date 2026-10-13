#!/bin/bash
set -e

mkdir -p /root/tracing-lab
cd /root/tracing-lab

# 1. Khoi tao package.json cho moi truong thuc hanh OpenTelemetry
cat << 'EOF' > package.json
{
  "name": "tracing-lab",
  "version": "1.0.0",
  "description": "Distributed Tracing with OpenTelemetry and Jaeger",
  "main": "order-service.js",
  "dependencies": {
    "express": "^4.19.2",
    "@opentelemetry/api": "^1.9.0",
    "@opentelemetry/sdk-node": "^0.52.1",
    "@opentelemetry/exporter-trace-otlp-http": "^0.52.1"
  }
}
EOF

# 2. Cai dat cac thu vien can thiet
npm install --no-audit --no-fund > /dev/null 2>&1

# 3. Pull truoc Docker image Jaeger de tiet kiem thoi gian
docker pull jaegertracing/all-in-one:1.53 > /dev/null 2>&1 || true

# 4. Danh dau hoan tat
touch /tmp/background-finished
