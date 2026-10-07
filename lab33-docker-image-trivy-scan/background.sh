#!/bin/bash
# Chi tao ma nguon va file cau hinh mau, khong cai dat nang de terminal mo ngay lap tuc

mkdir -p /root/container-security-lab
cd /root/container-security-lab

# 1. Tao package.json
cat << 'EOF' > package.json
{
  "name": "payment-service",
  "version": "1.0.0",
  "description": "Production Payment Gateway Microservice",
  "main": "server.js",
  "dependencies": {
    "express": "4.19.2"
  }
}
EOF

# 2. Tao server.js
cat << 'EOF' > server.js
const express = require('express');
const app = express();
app.use(express.json());

app.post('/api/payments/charge', (req, res) => {
  const { amount, currency } = req.body;
  res.json({
    status: 'SUCCESS',
    transactionId: 'txn_' + Date.now(),
    amount: amount || 100,
    currency: currency || 'USD'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'payment-service', version: '1.0.0' });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Payment Service dang chay tren cong ${PORT}`);
});
EOF

# 3. Tao Dockerfile ban dau (chua harden, chua phan quyen non-root)
cat << 'EOF' > Dockerfile
# Dockerfile ban dau (chua toi uu bao mat)
FROM node:16-alpine

WORKDIR /app

# Cai dat thua cong cu vao production image
RUN apk add --no-cache curl bash

COPY package*.json ./
RUN npm install --only=production

COPY . .

# Khong co USER -> chay voi quyen root (UID 0)
EXPOSE 3000
CMD ["node", "server.js"]
EOF

touch /tmp/background-finished
