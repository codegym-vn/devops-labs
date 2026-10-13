#!/bin/bash

# Luon danh dau hoan tat khi thoat script de tranh treo foreground
trap 'touch /tmp/background-finished' EXIT

mkdir -p /root/tracing-lab
cd /root/tracing-lab

# 1. Khoi tao package.json cho moi truong OpenTelemetry
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

# 2. Cai dat Node.js v18 neu he thong chua co san
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.gz | tar -xz -C /opt 2>/dev/null || true
  ln -sf /opt/node-v18.20.4-linux-x64/bin/node /usr/local/bin/node 2>/dev/null || true
  ln -sf /opt/node-v18.20.4-linux-x64/bin/npm /usr/local/bin/npm 2>/dev/null || true
fi

# 3. Cai dat thu vien Node trong background
export PATH="/usr/local/bin:/opt/node-v18.20.4-linux-x64/bin:$PATH"
npm install --no-audit --no-fund > /dev/null 2>&1 || true

# 4. Pull ngam Docker image Jaeger de tiet kiem thoi gian
docker pull jaegertracing/all-in-one:1.53 > /dev/null 2>&1 &

# 5. Danh dau hoan tat
touch /tmp/background-finished
