#!/bin/bash
# background.sh — Lab 14: FinOps

apt-get update -y > /dev/null 2>&1
apt-get install -y \
  python3 python3-pip \
  curl unzip jq bc \
  > /dev/null 2>&1

mkdir -p /root/.aws /opt/lab-data
cat > /root/.aws/credentials << 'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF
cat > /root/.aws/config << 'EOF'
[default]
region = ap-southeast-1
output = json
EOF

# Tạo dataset CUR mẫu (nhẹ, chỉ Python)
python3 << 'PYEOF'
import csv, random, datetime, os

services = [
    ("Amazon EC2", ["t3.large", "t3.medium", "t3.xlarge"], 0.0832, 0.1664),
    ("Elastic Load Balancing", ["ALB"], 0.008, 0.016),
    ("Amazon RDS", ["db.t3.medium"], 0.068, 0.136),
    ("Amazon S3", ["Standard"], 0.023, 0.046),
    ("Amazon CloudWatch", ["Metrics"], 0.30, 0.60),
]
projects = ["devops-training", "e-commerce", "data-platform", "internal-tools"]
envs = ["production", "staging", "development"]
owners = ["team-backend", "team-frontend", "team-data", "team-devops"]

rows = []
start = datetime.date(2024, 9, 1)
for day in range(30):
    date = start + datetime.timedelta(days=day)
    for svc_name, types, lo, hi in services:
        for _ in range(random.randint(2, 5)):
            rows.append({
                "UsageStartDate": str(date),
                "ProductName": svc_name,
                "UsageType": random.choice(types),
                "Cost": round(random.uniform(lo, hi) * random.randint(1, 6), 4),
                "Project": random.choice(projects),
                "Environment": random.choice(envs),
                "Owner": random.choice(owners),
                "Region": "ap-southeast-1",
            })

with open("/opt/lab-data/cost-usage-report.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)
PYEOF

# Tạo resource utilization dataset
cat > /opt/lab-data/resource-utilization.json << 'EOF'
[
  {"id":"i-001","name":"api-server-prod","type":"t3.large","avg_cpu":78.2,"avg_mem":65.0,"monthly_cost_usd":59.90},
  {"id":"i-002","name":"web-server-prod","type":"t3.medium","avg_cpu":45.1,"avg_mem":55.0,"monthly_cost_usd":29.95},
  {"id":"i-003","name":"worker-prod","type":"t3.large","avg_cpu":8.3,"avg_mem":22.0,"monthly_cost_usd":59.90},
  {"id":"i-004","name":"reporting-server","type":"t3.xlarge","avg_cpu":3.1,"avg_mem":12.0,"monthly_cost_usd":119.81},
  {"id":"i-005","name":"old-test-server","type":"t3.medium","avg_cpu":1.2,"avg_mem":8.0,"monthly_cost_usd":29.95}
]
EOF

touch /tmp/.lab_ready
