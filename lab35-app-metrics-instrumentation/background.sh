#!/bin/bash
# Chi tao ma nguon va file cau hinh mau, khong cai dat nang de terminal mo ngay lap tuc

mkdir -p /root/app-monitoring-lab
cd /root/app-monitoring-lab

# 1. Tao package.json
cat << 'EOF' > package.json
{
  "name": "order-api",
  "version": "1.0.0",
  "description": "Order Processing API with Metrics Instrumentation",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "prom-client": "^15.1.3"
  }
}
EOF

# 2. Tao server.js ban dau
cat << 'EOF' > server.js
const express = require('express');
const app = express();
app.use(express.json());

// Endpoint 1: Xu ly lay danh sach don hang
app.get('/api/orders', (req, res) => {
  res.json({
    status: 'SUCCESS',
    orders: [
      { id: 101, item: 'Laptop Dell XPS', amount: 1500 },
      { id: 102, item: 'Ban phim co Keychron', amount: 95 }
    ]
  });
});

// Endpoint 2: Xu ly thanh toan (mo phong do tre va loi 500)
app.post('/api/checkout', (req, res) => {
  const isError = Math.random() < 0.2; // 20% xac suat loi
  const delay = Math.floor(Math.random() * 250) + 50; // Do tre tu 50ms - 300ms

  setTimeout(() => {
    if (isError) {
      return res.status(500).json({ status: 'FAILED', message: 'Cong thanh toan khong phan hoi' });
    }
    res.json({ status: 'COMPLETED', transactionId: 'txn_' + Date.now() });
  }, delay);
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-api' });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order API dang chay tren cong ${PORT}`);
});
EOF

touch /tmp/background-finished
