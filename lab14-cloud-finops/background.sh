#!/bin/bash
# background.sh — Lab 14: FinOps với AWS CLI, LocalStack & Python

apt-get update -y > /dev/null 2>&1
apt-get install -y python3 python3-pip curl awscli jq > /dev/null 2>&1

# 1. Khởi động LocalStack hỗ trợ dịch vụ ec2
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2 \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:latest > /dev/null 2>&1

# 2. Cấu hình AWS CLI
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set default.region us-east-1
aws configure set default.output json

cat << 'EOF' > /usr/local/bin/awslocal
#!/bin/bash
/usr/bin/aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/awslocal

cat << 'EOF' > /usr/local/bin/aws
#!/bin/bash
/usr/bin/aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/aws

cat << 'EOF' >> /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

# 3. Chờ LocalStack sẵn sàng
MAX_RETRY=30
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
  if curl -s http://localhost:4566/_localstack/health | grep -q '"ec2": "available"\|"ec2": "running"'; then
    break
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

# 4. Khởi tạo 5 EC2 instances đại diện cho các cụm máy chủ trong công ty
VPC_ID=$(/usr/local/bin/aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
SUBNET_ID=$(/usr/local/bin/aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)

run_ec2() {
  local NAME=$1
  local TYPE=$2
  /usr/local/bin/aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type $TYPE \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --query 'Instances[0].InstanceId' --output text
}

SRV_API=$(run_ec2 "api-server-prod" "t3.large")
SRV_WEB=$(run_ec2 "web-server-prod" "t3.medium")
SRV_WORKER=$(run_ec2 "worker-prod" "t3.large")
SRV_REPORT=$(run_ec2 "reporting-server" "t3.xlarge")
SRV_TEST=$(run_ec2 "old-test-server" "t3.medium")

cat << EOF > /tmp/lab-env.sh
export VPC_ID=$VPC_ID
export SUBNET_ID=$SUBNET_ID
export SRV_API=$SRV_API
export SRV_WEB=$SRV_WEB
export SRV_WORKER=$SRV_WORKER
export SRV_REPORT=$SRV_REPORT
export SRV_TEST=$SRV_TEST
EOF

# 5. Sinh dataset CUR (Cost & Usage Report) 30 ngày
mkdir -p /opt/lab-data/budgets
python3 << 'PYEOF'
import csv, random, datetime

services = [
    ("EC2 - Compute", ["t3.large", "t3.medium", "t3.xlarge"], 0.08, 0.17),
    ("ELB - Load Balancer", ["ALB"], 0.008, 0.016),
    ("RDS - Database", ["db.t3.medium"], 0.068, 0.14),
    ("S3 - Storage", ["Standard"], 0.023, 0.05),
    ("CloudWatch - Monitoring", ["Metrics"], 0.10, 0.30),
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

print(f"\n=== Phân Bổ Chi Phí Theo {group_by} ===")
for k, v in sorted(costs.items(), key=lambda x: -x[1]):
    bar = "█" * int(v / 10)
    print(f"  {k:25s}: ${v:8.2f} {bar}")
print(f"\n  👉 Tổng Chi Phí: ${sum(costs.values()):.2f}")
PYEOF

# Script đánh giá Budget Alerts
cat > /opt/lab-data/budgets/eval-budgets.py << 'PYEOF'
#!/usr/bin/env python3
import json, csv, sys
from collections import defaultdict

with open("/opt/lab-data/budgets/config.json") as f:
    budgets_cfg = json.load(f)["budgets"]

# Tính tổng chi phí phát sinh (Actual)
costs_by_project = defaultdict(float)
total_cost = 0.0
with open("/opt/lab-data/cost-usage-report.csv") as f:
    for row in csv.DictReader(f):
        c = float(row["Cost"])
        total_cost += c
        costs_by_project[row.get("Project", "unknown")] += c

print("\n=== ĐÁNH GIÁ CẢNH BÁO NGÂN SÁCH (AWS BUDGET ALERTS) ===\n")
for b in budgets_cfg:
    name = b["name"]
    limit = b["limit_usd"]
    filter_proj = b.get("filter", {}).get("Project")
    actual = costs_by_project[filter_proj] if filter_proj else total_cost
    spent_pct = (actual / limit) * 100
    forecast_pct = spent_pct * 1.15  # Dự báo xu hướng

    print(f"📌 Budget: {name} (Giới hạn: ${limit:.2f})")
    print(f"   Thực chi (Actual): ${actual:.2f} ({spent_pct:.1f}%)")

    for a in b["alerts"]:
        thresh = a["threshold_pct"]
        atype = a["type"]
        notify = a["notify"]
        triggered = (spent_pct >= thresh) if atype == "ACTUAL" else (forecast_pct >= thresh)
        status = f"🚨 KÍCH HOẠT CẢNH BÁO -> Gửi tới {notify}" if triggered else "✅ Bình thường"
        print(f"   - Rule [{atype} >= {thresh}%]: {status}")
    print()
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
        if cpu < 5:    rec = "🚨 TERMINATE hoặc tắt ngay"
        elif cpu < 15: rec = "⚡ RIGHT-SIZE: Downgrade instance type"
        else:          rec = "📅 Lập lịch tự động Stop ngoài giờ làm việc"
        print(f"  {inst['name']:25s} CPU:{cpu:5.1f}%  ${cost:.2f}/tháng")
        print(f"  → Khuyến nghị FinOps: {rec}\n")
    else:
        print(f"  ✅ {inst['name']:25s} CPU:{cpu:5.1f}%  ${cost:.2f}/tháng (Tối ưu tốt)\n")

print(f"👉 Tổng tài nguyên lãng phí (CPU < {threshold}%): {idle_count}/{len(instances)} instances")
PYEOF

chmod +x /opt/lab-data/*.py
chmod +x /opt/lab-data/budgets/*.py

touch /tmp/.lab_ready
