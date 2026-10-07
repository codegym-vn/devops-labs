#!/bin/bash
set -e

# 1. Cai dat Trivy binary
if ! command -v trivy > /dev/null 2>&1; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
  chmod +x /usr/local/bin/trivy
fi

# 2. Cai dat Gitleaks binary
if ! command -v gitleaks > /dev/null 2>&1; then
  curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz \
    | tar -xz -C /usr/local/bin gitleaks
  chmod +x /usr/local/bin/gitleaks
fi

# 3. Cai dat Node.js neu chua co
if ! command -v node > /dev/null 2>&1; then
  apt-get update -qq > /dev/null 2>&1
  apt-get install -y -qq nodejs npm jq > /dev/null 2>&1
fi

# 4. Khoi tao thu muc du an
mkdir -p /root/security-gate-lab
cd /root/security-gate-lab

git config --global user.name "DevOps Learner"
git config --global user.email "learner@devops.lab"
git config --global init.defaultBranch main
git init -q

cat << 'EOF' > package.json
{
  "name": "devsecops-gate-demo",
  "version": "1.0.0",
  "description": "Demo service for multi-tier CI/CD Security Gates",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "node -e \"console.log('Unit test passed'); process.exit(0)\""
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF

cat << 'EOF' > server.js
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
EOF

cat << 'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --only=production
COPY server.js ./
USER 10001
EXPOSE 3000
CMD ["node", "server.js"]
EOF

git add .
git commit -q -m "feat: khoi tao ma nguon dich vu devsecops demo"

touch /tmp/background-finished
