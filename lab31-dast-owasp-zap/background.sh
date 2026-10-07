#!/bin/bash
set -e

# 1. Cai dat tien ich co ban
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq curl jq python3 python3-pip python3-requests nodejs npm lsof > /dev/null 2>&1

# 2. Khoi tao ma nguon ung dung Web muc tieu (Target Web App)
mkdir -p /root/dast-target-app
cd /root/dast-target-app

cat << 'EOF' > package.json
{
  "name": "dast-target-webapp",
  "version": "1.0.0",
  "description": "Target web application for DAST OWASP ZAP scanning",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "helmet": "^7.1.0"
  }
}
EOF

npm install --silent > /dev/null 2>&1

cat << 'EOF' > server.js
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Trang chu voi form dang nhap (Chua cau hinh cac HTTP Security Headers)
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Portal Noi Bo - DevSecOps Demo</title>
  <style>
    body { font-family: sans-serif; margin: 40px; background: #f4f6f8; }
    .card { background: white; padding: 24px; border-radius: 8px; max-width: 400px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    input { width: 100%; padding: 8px; margin: 8px 0 16px; box-sizing: border-box; }
    button { background: #0066cc; color: white; border: none; padding: 10px 16px; border-radius: 4px; cursor: pointer; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Dang Nhap He Thong</h2>
    <form action="/login" method="POST">
      <label>Ten dang nhap:</label>
      <input type="text" name="username" required>
      <label>Mat khau:</label>
      <input type="password" name="password" required>
      <button type="submit">Xac Nhan</button>
    </form>
  </div>
</body>
</html>
  `);
});

// Endpoint API suc khoe
app.get('/api/health', (req, res) => {
  res.json({ status: 'UP', timestamp: new Date().toISOString() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Target Web Application dang chay tren cong ${PORT}`);
});
EOF

# 3. Cai dat cong cu zap-baseline CLI mo phong chuan OWASP ZAP v2.14
cat << 'EOF' > /usr/local/bin/zap-baseline.py
#!/usr/bin/env python3
import sys
import argparse
import json
import urllib.request
import urllib.error
from datetime import datetime

def main():
    parser = argparse.ArgumentParser(description="OWASP ZAP Baseline Scan CLI")
    parser.add_argument("-t", "--target", required=True, help="Target URL")
    parser.add_argument("-r", "--html-report", help="Output HTML report")
    parser.add_argument("-J", "--json-report", help="Output JSON report")
    parser.add_argument("-w", "--warn-only", action="store_true", help="Do not exit with error on warnings")
    args = parser.parse_args()

    target = args.target
    print(f"2026-10-07 10:00:00,000 [ZAP-CLI] Starting OWASP ZAP Baseline Scan on: {target}")
    
    try:
        req = urllib.request.Request(target, headers={'User-Agent': 'Mozilla/5.0 (OWASP ZAP)'})
        with urllib.request.urlopen(req, timeout=10) as response:
            headers = {k.lower(): v for k, v in response.headers.items()}
            status_code = response.getcode()
            body = response.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"ERROR: Khong the ket noi den muc tieu {target}: {e}")
        sys.exit(2)

    alerts = []
    
    # Kiem tra 1: X-Frame-Options (Clickjacking - CWE-1021)
    if 'x-frame-options' not in headers and 'content-security-policy' not in headers:
        alerts.append({
            "pluginId": "10020",
            "name": "Anti-clickjacking Header (X-Frame-Options) Not Set",
            "risk": "Medium",
            "confidence": "Medium",
            "cweid": "1021",
            "wascid": "15",
            "description": "The response does not protect against 'ClickJacking' attacks via X-Frame-Options or CSP frame-ancestors.",
            "solution": "Add 'X-Frame-Options: SAMEORIGIN' or 'X-Frame-Options: DENY' header."
        })
    elif 'x-frame-options' in headers:
        pass

    # Kiem tra 2: Content-Security-Policy (CSP - CWE-693)
    if 'content-security-policy' not in headers:
        alerts.append({
            "pluginId": "10038",
            "name": "Content Security Policy (CSP) Header Not Set",
            "risk": "Medium",
            "confidence": "High",
            "cweid": "693",
            "wascid": "15",
            "description": "Content Security Policy (CSP) is an added layer of security that helps detect and mitigate attacks like Cross-Site Scripting (XSS) and data injection.",
            "solution": "Ensure that your web server, application server, load balancer, etc. is configured to set Content-Security-Policy header."
        })

    # Kiem tra 3: X-Content-Type-Options (MIME Sniffing - CWE-16)
    if 'x-content-type-options' not in headers:
        alerts.append({
            "pluginId": "10021",
            "name": "X-Content-Type-Options Header Missing",
            "risk": "Low",
            "confidence": "Medium",
            "cweid": "16",
            "wascid": "15",
            "description": "The Anti-MIME-Sniffing header X-Content-Type-Options was not set to 'nosniff'.",
            "solution": "Ensure that the application sets 'X-Content-Type-Options: nosniff'."
        })

    # Kiem tra 4: Server Leaks Information via X-Powered-By (CWE-200)
    if 'x-powered-by' in headers:
        alerts.append({
            "pluginId": "10004",
            "name": "Server Leaks Information via 'X-Powered-By' HTTP Response Header Field",
            "risk": "Low",
            "confidence": "High",
            "cweid": "200",
            "wascid": "13",
            "description": f"The web/application server is leaking version information via 'X-Powered-By: {headers['x-powered-by']}'.",
            "solution": "Ensure that your web server does not send the 'X-Powered-By' header."
        })

    # In ket qua console chuan OWASP ZAP
    print("\n------------------------------------------------------------")
    print(f"PASS: 1\tWARN: {len(alerts)}\tFAIL: 0\tSKIP: 0")
    print("------------------------------------------------------------")
    for a in alerts:
        print(f"WARN-NEW: {a['name']} [{a['pluginId']}] x 1 ({target}) - Risk: {a['risk']}")

    # Ghi bao cao JSON
    if args.json_report:
        report_data = {
            "@version": "2.14.0",
            "@generated": datetime.now().isoformat(),
            "site": [{"@name": target, "@host": "localhost", "@port": "3000", "alerts": alerts}]
        }
        with open(args.json_report, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2)
        print(f"\nDa xuat bao cao JSON: {args.json_report}")

    # Ghi bao cao HTML
    if args.html_report:
        rows = "".join([f"<tr><td><b>{a['name']}</b><br><small>{a['description']}</small></td><td>{a['risk']}</td><td>{a['cweid']}</td><td>{a['solution']}</td></tr>" for a in alerts])
        html = f"""<!DOCTYPE html><html><head><title>OWASP ZAP Report</title><style>body{{font-family:sans-serif;margin:30px}} table{{width:100%;border-collapse:collapse;margin-top:20px}} th,td{{border:1px solid #ccc;padding:10px;text-align:left}} th{{background:#2c3e50;color:white}}</style></head><body><h1>OWASP ZAP Baseline Scan Report</h1><p><b>Target:</b> {target}</p><p><b>Total Findings:</b> {len(alerts)}</p><table><tr><th>Alert</th><th>Risk</th><th>CWE</th><th>Solution</th></tr>{rows}</table></body></html>"""
        with open(args.html_report, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f"Da xuat bao cao HTML: {args.html_report}")

    if alerts and not args.warn_only:
        print(f"\n[ZAP SCAN FINISHED] Phat hien {len(alerts)} rui ro an ninh dong (DAST)!")
        sys.exit(1)
    else:
        print("\n[ZAP SCAN FINISHED] Hoan thanh quet DAST khong phat hien canh bao moi!")
        sys.exit(0)

if __name__ == "__main__":
    main()
EOF

chmod +x /usr/local/bin/zap-baseline.py
ln -sf /usr/local/bin/zap-baseline.py /usr/local/bin/zap-baseline

touch /tmp/background-finished
