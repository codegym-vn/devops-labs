#!/bin/bash
set -e

# 1. Cau hinh bo nho Elasticsearch cho SonarQube
sysctl -w vm.max_map_count=262144 > /dev/null 2>&1 || true

# 2. Cai dat tien ich
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq curl unzip jq nodejs npm > /dev/null 2>&1

# 3. Cai dat SonarScanner CLI
if ! command -v sonar-scanner > /dev/null 2>&1; then
  curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o /tmp/sonar-scanner.zip
  unzip -q /tmp/sonar-scanner.zip -d /opt
  rm -f /tmp/sonar-scanner.zip
  ln -sf /opt/sonar-scanner-*/bin/sonar-scanner /usr/local/bin/sonar-scanner
fi

# 4. Khoi chay SonarQube Server container
if ! docker ps -a | grep -q "sonarqube"; then
  docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community > /dev/null 2>&1
fi

# 5. Khoi tao thu muc du an mau
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
