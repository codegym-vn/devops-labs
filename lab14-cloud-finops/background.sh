#!/bin/bash
# background.sh — Lab 14: FinOps

apt-get update -y > /dev/null 2>&1
apt-get install -y python3 python3-pip curl > /dev/null 2>&1

mkdir -p /opt/lab-data

# Dataset chi phí 30 ngày
python3 << 'PYEOF'
import csv, random, datetime

services = [
    ("Compute (VM)", ["t3.large", "t3.medium", "t3.xlarge"], 0.08, 0.17),
    ("Load Balancer", ["ALB"], 0.008, 0.016),
    ("Database",      ["db.t3.medium"], 0.068, 0.14),
    ("Object Storage",["Standard"], 0.023, 0.05),
    ("Monitoring",    ["Metrics"], 0.10, 0.30),
]
projects = ["e-commerce", "data-platform", "internal-tools"]
envs = ["production", "staging", "development"]
owners = ["team-backend", "team-frontend", "team-data", "team-devops"]

rows = []
start = datetime.date(2024, 9, 1)
for day in range(30):
    date = start + datetime.timedelta(days=day)
    for svc, types, lo, hi in services:
        for _ in range(random.randint(2, 5)):
            rows.append({
                "UsageStartDate": str(date),
                "ProductName": svc,
                "UsageType": random.choice(types),
                "Cost": round(random.uniform(lo, hi) * random.randint(1, 6), 4),
                "Project": random.choice(projects),
                "Environment": random.choice(envs),
                "Owner": random.choice(owners),
            })

with open("/opt/lab-data/cost-usage-report.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader(); w.writerows(rows)
print(f"Generated {len(rows)} rows")
PYEOF

# Dataset utilization
cat > /opt/lab-data/resource-utilization.json << 'JSONEOF'
[
  {"id":"srv-001","name":"api-server-prod",  "type":"t3.large", "avg_cpu":78.2,"avg_mem":65.0,"monthly_cost_usd":59.90},
  {"id":"srv-002","name":"web-server-prod",  "type":"t3.medium","avg_cpu":45.1,"avg_mem":55.0,"monthly_cost_usd":29.95},
  {"id":"srv-003","name":"worker-prod",      "type":"t3.large", "avg_cpu":8.3, "avg_mem":22.0,"monthly_cost_usd":59.90},
  {"id":"srv-004","name":"reporting-server", "type":"t3.xlarge","avg_cpu":3.1, "avg_mem":12.0,"monthly_cost_usd":119.81},
  {"id":"srv-005","name":"old-test-server",  "type":"t3.medium","avg_cpu":1.2, "avg_mem":8.0, "monthly_cost_usd":29.95}
]
JSONEOF

# Script phân tích CUR
cat > /opt/lab-data/analyze-cost.py << 'PYEOF'
#!/usr/bin/env python3
import csv, sys
from collections import defaultdict

args = sys.argv[1:]
file_path = args[args.index("--file") + 1] if "--file" in args else "/opt/lab-data/cost-usage-report.csv"
group_by = args[args.index("--group-by") + 1] if "--group-by" in args else "ProductName"

costs = defaultdict(float)
with open(file_path) as f:
    for row in csv.DictReader(f):
        costs[row.get(group_by, "unknown")] += float(row["Cost"])

print(f"\n=== Chi phí theo {group_by} ===")
for k, v in sorted(costs.items(), key=lambda x: -x[1]):
    bar = "█" * int(v / 10)
    print(f"  {k:25s}: ${v:8.2f} {bar}")
print(f"\n  Tổng: ${sum(costs.values()):.2f}")
PYEOF

# Script tìm idle resources
cat > /opt/lab-data/find-idle-resources.py << 'PYEOF'
#!/usr/bin/env python3
import json, sys

args = sys.argv[1:]
metrics_file = args[args.index("--metrics") + 1] if "--metrics" in args else "/opt/lab-data/resource-utilization.json"
threshold = int(args[args.index("--cpu-threshold") + 1]) if "--cpu-threshold" in args else 30

with open(metrics_file) as f:
    instances = json.load(f)

print(f"\n=== Phân tích tài nguyên idle (CPU threshold: {threshold}%) ===\n")
idle_count = 0
for inst in instances:
    cpu = inst["avg_cpu"]
    cost = inst["monthly_cost_usd"]
    if cpu < threshold:
        idle_count += 1
        if cpu < 5:    rec = " TERMINATE hoặc right-size ngay"
        elif cpu < 15: rec = " Downgrade instance type"
        else:          rec = " Xem xét Schedule stop ngoài giờ"
        print(f"  {inst['name']:25s} CPU:{cpu:5.1f}%  ${cost:.2f}/tháng")
        print(f"  → {rec}\n")
    else:
        print(f"   {inst['name']:25s} CPU:{cpu:5.1f}%  ${cost:.2f}/tháng (OK)\n")

print(f"Tổng idle (CPU < {threshold}%): {idle_count}/{len(instances)} instances")
PYEOF

chmod +x /opt/lab-data/*.py
docker pull nginx:alpine > /dev/null 2>&1 &

touch /tmp/.lab_ready
