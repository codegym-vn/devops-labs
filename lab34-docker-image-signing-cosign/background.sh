#!/bin/bash
# Chi tao ma nguon va file cau hinh mau, khong cai dat nang de terminal mo ngay lap tuc

mkdir -p /root/cosign-signing-lab
cd /root/cosign-signing-lab

# 1. Tao package.json
cat << 'EOF' > package.json
{
  "name": "order-service",
  "version": "1.0.0",
  "description": "Production Order Processing Service",
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

app.post('/api/orders', (req, res) => {
  const { item, quantity } = req.body;
  res.json({
    status: 'ORDER_CREATED',
    orderId: 'ord_' + Math.floor(Math.random() * 100000),
    item: item || 'Laptop',
    quantity: quantity || 1
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'order-service', version: '1.0.0' });
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Order Service dang chay tren cong ${PORT}`);
});
EOF

# 3. Tao Dockerfile
cat << 'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY server.js ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
EOF

touch /tmp/background-finished
