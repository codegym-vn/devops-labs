#!/bin/bash
# Chi tao file ma nguon mau, khong cai dat gi de Terminal mo ngay lap tuc

mkdir -p /root/dast-target-app/zap-reports
chmod 777 /root/dast-target-app/zap-reports
cd /root/dast-target-app

cat << 'EOF' > package.json
{
  "name": "dast-target-webapp",
  "version": "1.0.0",
  "description": "Target web application for DAST OWASP ZAP scanning",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "helmet": "^7.1.0"
  }
}
EOF

cat << 'EOF' > server.js
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.urlencoded({ extended: true }));

// Trang chu voi form dang nhap, chua cau hinh HTTP Security Headers
app.get('/', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="vi">
<head><meta charset="UTF-8"><title>Portal Noi Bo</title></head>
<body>
  <h2>Dang Nhap He Thong</h2>
  <form action="/login" method="POST">
    <input type="text" name="username" placeholder="Ten dang nhap">
    <input type="password" name="password" placeholder="Mat khau">
    <button type="submit">Dang nhap</button>
  </form>
</body>
</html>`);
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'UP', timestamp: new Date().toISOString() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Target Web Application dang chay tren cong ${PORT}`);
});
EOF

touch /tmp/background-finished
