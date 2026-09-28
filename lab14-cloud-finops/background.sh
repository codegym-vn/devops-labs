#!/bin/bash
# background.sh — Lab 14: FinOps với AWS CLI, LocalStack & Python

echo "Khởi tạo môi trường FinOps Lab..." > /tmp/lab-status.log

# 1. Khởi động LocalStack chạy ngầm ngay từ đầu với tag 3.8
echo "Đang khởi chạy LocalStack container..." > /tmp/lab-status.log
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=ec2 \
  -e DEFAULT_REGION=us-east-1 \
  localstack/localstack:3.8 >/dev/null 2>&1

# 2. Giải phóng triệt để lock apt nếu Ubuntu đang chạy auto-update ngầm
echo "Đang dọn dẹp tiến trình apt hệ thống..." > /tmp/lab-status.log
systemctl stop unattended-upgrades.service apt-daily.service apt-daily-upgrade.service apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
killall -9 apt apt-get dpkg unattended-upgrade >/dev/null 2>&1 || true
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock* /var/cache/apt/archives/lock* >/dev/null 2>&1 || true
dpkg --configure -a >/dev/null 2>&1 || true

# 3. Cài đặt các công cụ cần thiết (Python, curl, unzip, jq)
echo "Đang cài đặt Python & công cụ bổ trợ..." > /tmp/lab-status.log
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq --no-install-recommends python3 python3-pip curl unzip jq >/dev/null 2>&1

# 4. Cài đặt AWS CLI v2 chính thức (chuẩn AWS, hỗ trợ AWS_ENDPOINT_URL gốc)
if ! command -v aws >/dev/null 2>&1; then
  echo "Đang cài đặt AWS CLI v2..." > /tmp/lab-status.log
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o /tmp/awscliv2.zip -d /tmp
  else
    python3 -c "
import zipfile, os
with zipfile.ZipFile('/tmp/awscliv2.zip', 'r') as z:
    for info in z.infolist():
        z.extract(info, '/tmp')
        mode = info.external_attr >> 16
        if mode:
            os.chmod('/tmp/' + info.filename, mode)
" 2>/dev/null
  fi
  chmod +x /tmp/aws/install /tmp/aws/dist/aws 2>/dev/null || true
  /tmp/aws/install --update >/dev/null 2>&1 || true
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Đảm bảo symlink ở cả /usr/local/bin và /usr/bin
if [ -x /usr/local/aws-cli/v2/current/bin/aws ] && [ ! -x /usr/local/bin/aws ]; then
  ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
fi
if [ -x /usr/local/bin/aws ] && [ ! -x /usr/bin/aws ]; then
  ln -sf /usr/local/bin/aws /usr/bin/aws
fi

# 5. Cấu hình AWS CLI (Native endpoint_url)
mkdir -p /root/.aws /home/ubuntu/.aws 2>/dev/null

cat << 'EOF' > /root/.aws/config
[default]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
EOF

cat << 'EOF' > /root/.aws/credentials
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

cp -r /root/.aws /home/ubuntu/ 2>/dev/null || true
chown -R ubuntu:ubuntu /home/ubuntu/.aws 2>/dev/null || true

# Tạo lệnh awslocal bổ trợ
cat << 'EOF' > /usr/local/bin/awslocal
#!/bin/bash
exec aws --endpoint-url=http://localhost:4566 "$@"
EOF
chmod +x /usr/local/bin/awslocal
ln -sf /usr/local/bin/awslocal /usr/bin/awslocal 2>/dev/null || true

# Thiết lập biến môi trường hệ thống
cat << 'EOF' > /etc/profile.d/aws.sh
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF

for rc in /root/.bashrc /home/ubuntu/.bashrc; do
  if [ -f "$rc" ] && ! grep -q "AWS_ENDPOINT_URL" "$rc"; then
    cat << 'EOF' >> "$rc"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566
alias awslocal="aws --endpoint-url=http://localhost:4566"
EOF
  fi
done

# 6. Chờ LocalStack sẵn sàng
echo "Đang chờ dịch vụ LocalStack EC2 sẵn sàng..." > /tmp/lab-status.log
MAX_RETRY=50
RETRY=0
while [ $RETRY -lt $MAX_RETRY ]; do
  if curl -s http://localhost:4566/_localstack/health 2>/dev/null | grep -q '"ec2": "available"\|"ec2": "running"'; then
    break
  fi
  if ! docker ps -q --filter "name=localstack" 2>/dev/null | grep -q .; then
    echo "Đang tải LocalStack Docker image (khoảng 20-35s)..." > /tmp/lab-status.log
  else
    echo "LocalStack đang khởi tạo dịch vụ EC2..." > /tmp/lab-status.log
  fi
  sleep 2
  RETRY=$((RETRY+1))
done

# 7. Khởi tạo 5 EC2 instances đại diện cho các cụm máy chủ trong công ty
echo "Đang khởi tạo các máy ảo EC2 mẫu trên LocalStack..." > /tmp/lab-status.log
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text 2>/dev/null)
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text 2>/dev/null)

run_ec2() {
  local NAME=$1
  local TYPE=$2
  aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type $TYPE \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --query 'Instances[0].InstanceId' --output text 2>/dev/null
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

# 8. Sinh dataset CUR (Cost & Usage Report) 30 ngày & scripts phân tích
echo "Đang tạo tập dữ liệu FinOps mẫu (CUR 30 ngày)..." > /tmp/lab-status.log
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
    forecast_pct = spent_pct * 1.15

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

echo "Môi trường đã sẵn sàng!" > /tmp/lab-status.log
touch /tmp/.lab_ready
