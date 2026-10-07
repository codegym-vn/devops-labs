#!/bin/bash
set -e

# 1. Cau hinh bo nho Elasticsearch cho SonarQube
sysctl -w vm.max_map_count=262144 > /dev/null 2>&1 || true

# 2. Khoi tao ngay thu muc du an mau
mkdir -p /root/sonarqube-lab/src
cd /root/sonarqube-lab

cat << 'EOF' > package.json
{
  "name": "sonarqube-demo-service",
  "version": "1.0.0",
  "description": "Demo service for SonarQube static code analysis",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF

cat << 'EOF' > src/app.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Code Smell 1: Bien khong su dung (Unused variable)
const unusedVariable = "This is not used anywhere";

// Code Smell 2: Password hardcode dang comment
// const adminPass = "123456";

// Endpoint kiem tra suc khoe
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// Endpoint chao mung
app.get('/', (req, res) => {
  res.send('Welcome to SonarQube SAST Demo Service');
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
EOF

touch /tmp/background-finished
