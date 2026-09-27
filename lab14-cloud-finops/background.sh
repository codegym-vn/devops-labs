#!/bin/bash
# background.sh — Lab 14: FinOps
set -e
LOG="/var/log/lab-init.log"
exec > "$LOG" 2>&1

echo "[$(date)] Khởi tạo Lab 14: FinOps..."

apt-get update -q
apt-get install -y -q python3 python3-pip curl unzip jq bc

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/ && /tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

pip3 install -q localstack localstack-client

mkdir -p /root/.aws
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

cat >> /root/.bashrc << 'EOF'
alias aws="aws --endpoint-url=http://localhost:4566"
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
EOF

LOCALSTACK_VOLUME_DIR=/var/lib/localstack localstack start -d

for i in $(seq 1 60); do
  curl -sf http://localhost:4566/_localstack/health | grep -q '"ec2": "available"' && break
  sleep 2
done

# Tạo tài nguyên mẫu để học viên gắn tags
BASE="--endpoint-url=http://localhost:4566"
export AWS_DEFAULT_REGION=ap-southeast-1

VPC_ID=$(aws $BASE ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --query 'Vpc.VpcId' --output text)
SUBNET_ID=$(aws $BASE ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
SG_ID=$(aws $BASE ec2 create-security-group \
  --group-name lab-sg --description "Lab SG" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)

# Tạo 5 EC2 instances mô phỏng môi trường production
INSTANCE_IDS=()
NAMES=("api-server-prod" "web-server-prod" "worker-prod" "reporting-server" "old-test-server")
TYPES=("t3.large" "t3.medium" "t3.large" "t3.xlarge" "t3.medium")
for i in 0 1 2 3 4; do
  ID=$(aws $BASE ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type ${TYPES[$i]} \
    --subnet-id $SUBNET_ID \
    --security-group-ids $SG_ID \
    --query 'Instances[0].InstanceId' --output text)
  INSTANCE_IDS+=($ID)
  echo "Instance ${NAMES[$i]}: $ID"
done

cat > /tmp/lab-env.sh << EOF
export VPC_ID=$VPC_ID
export SUBNET_ID=$SUBNET_ID
export SG_ID=$SG_ID
export INSTANCE_IDS="${INSTANCE_IDS[@]}"
export INST_0=${INSTANCE_IDS[0]}
export INST_1=${INSTANCE_IDS[1]}
export INST_2=${INSTANCE_IDS[2]}
export INST_3=${INSTANCE_IDS[3]}
export INST_4=${INSTANCE_IDS[4]}
EOF

# Tạo dataset Cost & Usage Report mẫu (30 ngày, format AWS CUR thật)
mkdir -p /opt/lab-data

python3 << 'PYEOF'
import csv, random, datetime

services = [
    ("Amazon EC2", ["t3.large", "t3.medium", "t3.xlarge"], 0.0832, 0.0416, 0.1664),
    ("Elastic Load Balancing", ["ALB"], 0.008, 0.008, 0.008),
    ("Amazon RDS", ["db.t3.medium"], 0.068, 0.068, 0.068),
    ("Amazon S3", ["Standard"], 0.023, 0.023, 0.023),
    ("Amazon CloudWatch", ["Metrics"], 0.30, 0.30, 0.30),
    ("AWS Data Transfer", ["Out"], 0.09, 0.09, 0.09),
]

projects = ["devops-training", "e-commerce", "data-platform", "internal-tools"]
envs = ["production", "staging", "development"]
owners = ["team-backend", "team-frontend", "team-data", "team-devops"]

rows = []
start = datetime.date(2024, 9, 1)
for day in range(30):
    date = start + datetime.timedelta(days=day)
    for svc_name, types, lo, mid, hi in services:
        for _ in range(random.randint(2, 5)):
            cost = round(random.uniform(lo, hi) * random.randint(1, 8), 4)
            rows.append({
                "UsageStartDate": str(date),
                "ProductName": svc_name,
                "UsageType": random.choice(types),
                "Cost": cost,
                "Project": random.choice(projects),
                "Environment": random.choice(envs),
                "Owner": random.choice(owners),
                "Region": "ap-southeast-1",
            })

with open("/opt/lab-data/cost-usage-report.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)

print(f"Đã tạo {len(rows)} dòng Cost & Usage Report")
PYEOF

# Dataset utilization cho idle analysis
python3 << 'PYEOF'
import json, random

instances = [
    {"id": "i-001", "name": "api-server-prod",     "type": "t3.large",  "avg_cpu": 78.2, "avg_mem": 65.0, "region": "ap-southeast-1a"},
    {"id": "i-002", "name": "web-server-prod",      "type": "t3.medium", "avg_cpu": 45.1, "avg_mem": 55.0, "region": "ap-southeast-1a"},
    {"id": "i-003", "name": "worker-prod",           "type": "t3.large",  "avg_cpu": 8.3,  "avg_mem": 22.0, "region": "ap-southeast-1b"},
    {"id": "i-004", "name": "reporting-server",      "type": "t3.xlarge", "avg_cpu": 3.1,  "avg_mem": 12.0, "region": "ap-southeast-1a"},
    {"id": "i-005", "name": "old-test-server",       "type": "t3.medium", "avg_cpu": 1.2,  "avg_mem": 8.0,  "region": "ap-southeast-1b"},
]

pricing = {"t3.large": 0.0832, "t3.medium": 0.0416, "t3.xlarge": 0.1664}

for inst in instances:
    inst["monthly_cost_usd"] = round(pricing[inst["type"]] * 24 * 30, 2)

with open("/opt/lab-data/resource-utilization.json", "w") as f:
    json.dump(instances, f, indent=2)
print("Đã tạo resource-utilization.json")
PYEOF

# Script phân tích cost
cat > /opt/lab-data/analyze-cost.py << 'PYEOF'
#!/usr/bin/env python3
import csv, sys, argparse
from collections import defaultdict

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--group-by", required=True)
    args = parser.parse_args()

    totals = defaultdict(float)
    grand = 0.0
    with open(args.file) as f:
        for row in csv.DictReader(f):
            key = row.get(args.group_by.replace("tag:", "").title(), "Unknown")
            if args.group_by.startswith("tag:"):
                tag = args.group_by.split(":")[1].capitalize()
                key = row.get(tag, "Untagged")
            totals[key] += float(row["Cost"])
            grand += float(row["Cost"])

    print(f"\n{'Nhóm':<30} {'Chi phí (USD)':>15} {'%':>8}")
    print("─" * 56)
    for k, v in sorted(totals.items(), key=lambda x: -x[1]):
        pct = v / grand * 100 if grand else 0
        print(f"  {k:<28} ${v:>13.2f} {pct:>7.1f}%")
    print("─" * 56)
    print(f"  {'TỔNG':<28} ${grand:>13.2f} {'100.0':>7}%\n")

main()
PYEOF
chmod +x /opt/lab-data/analyze-cost.py

# Script phân tích idle resources
cat > /opt/lab-data/find-idle-resources.py << 'PYEOF'
#!/usr/bin/env python3
import json, argparse

PRICING = {"t3.micro": 0.0104, "t3.small": 0.0208, "t3.medium": 0.0416, "t3.large": 0.0832, "t3.xlarge": 0.1664}

def recommend(inst):
    cpu, tp = inst["avg_cpu"], inst["type"]
    cost = inst["monthly_cost_usd"]
    if cpu < 5:
        new = "t3.micro"; savings = cost - PRICING.get(new, 0) * 24 * 30
        return f"🔴 NGƯNG hoặc schedule stop ngoài giờ — tiết kiệm ${savings:.0f}/tháng"
    elif cpu < 15:
        types = list(PRICING.keys())
        idx = types.index(tp) if tp in types else -1
        new = types[max(0, idx-1)]
        savings = cost - PRICING.get(new, 0) * 24 * 30
        return f"🟡 Downgrade từ {tp} → {new} — tiết kiệm ${savings:.0f}/tháng"
    elif cpu < 30:
        return f"🟢 Xem xét Reserved Instance (1 năm) — tiết kiệm ~30%"
    return f"✅ Utilization tốt ({cpu:.1f}%) — không cần thay đổi"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metrics", required=True)
    parser.add_argument("--cpu-threshold", type=float, default=10)
    args = parser.parse_args()

    with open(args.metrics) as f:
        data = json.load(f)

    print(f"\n{'Instance':<25} {'Type':<12} {'CPU avg':>8} {'$/tháng':>10}  Đề xuất")
    print("─" * 100)

    total_cost = 0; total_savings = 0
    for inst in data:
        rec = recommend(inst)
        print(f"  {inst['name']:<23} {inst['type']:<12} {inst['avg_cpu']:>7.1f}% ${inst['monthly_cost_usd']:>9.2f}  {rec}")
        total_cost += inst["monthly_cost_usd"]
        if "tiết kiệm" in rec:
            try: total_savings += float(rec.split("$")[1].split("/")[0])
            except: pass

    print("─" * 100)
    print(f"\n  Tổng chi phí hiện tại : ${total_cost:.2f}/tháng")
    print(f"  Tiết kiệm tiềm năng   : ${total_savings:.0f}/tháng ({total_savings/total_cost*100:.0f}%)\n")

main()
PYEOF
chmod +x /opt/lab-data/find-idle-resources.py

echo "[$(date)] ✅ Lab 14 sẵn sàng"
touch /tmp/lab-ready
