#!/bin/bash
set -e

# 1. Cai dat Gitleaks binary
if ! command -v gitleaks > /dev/null 2>&1; then
  curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz \
    | tar -xz -C /usr/local/bin gitleaks
  chmod +x /usr/local/bin/gitleaks
fi

# 2. Khoi tao kho ma nguon mau co tinh chua secrets de hoc vien thuc hanh
mkdir -p /root/secret-leak-lab
cd /root/secret-leak-lab

git config --global user.name "DevOps Learner"
git config --global user.email "learner@devops.lab"
git config --global init.defaultBranch main
git init -q

# File 1: server.js co ban
cat << 'EOF' > server.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/status', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# File 2: config.json vo tinh hardcode AWS API Key
cat << 'EOF' > config.json
{
  "serviceName": "payment-gateway",
  "aws": {
    "region": "us-east-1",
    "accessKeyId": "AKIAIOSFODNN7EXAMPLE",
    "secretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  }
}
EOF

git add server.js config.json
git commit -q -m "feat: khoi tao ma nguon dich vu payment gateway"

# File 3: database.js o commit thu 2 co chuoi ket noi chua password
cat << 'EOF' > database.js
const { Pool } = require('pg');

// Ket noi Database truc tiep bang chuoi connection string chua password
const connectionString = "postgres://admin_user:P@ssw0rdSecure2026!@postgres-db.internal:5432/finance_db";

const pool = new Pool({ connectionString });
module.exports = pool;
EOF

git add database.js
git commit -q -m "feat: tich hop ket noi postgresql database"

touch /tmp/background-finished
