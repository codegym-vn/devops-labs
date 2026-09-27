# Bước 1: Tagging — Phân bổ chi phí theo nhóm

## Lý thuyết

**Tag** (AWS) / **Label** (GCP) / **Tag** (Azure) — metadata gắn lên tài nguyên để trả lời câu hỏi:
*"Chi phí $10,000 tháng này đến từ đâu?"*

Chuẩn tagging phổ biến:

| Tag | Ý nghĩa | Ví dụ |
|-----|---------|-------|
| `Name` | Tên tài nguyên | `web-server-prod` |
| `Project` | Dự án/sản phẩm | `e-commerce` |
| `Environment` | Môi trường | `production`, `staging`, `dev` |
| `Owner` | Team chịu trách nhiệm | `team-backend` |
| `CostCenter` | Mã trung tâm chi phí | `CC-001` |

Không có tag → không biết tài nguyên đó phục vụ mục đích gì → không thể phân bổ chi phí.

Trong Docker, tag = `--label` khi chạy container.

---

## Thực hành

### 1.1 — Khởi động 5 servers với tagging đúng chuẩn

```bash
# Hàm tạo server với labels (tags) đúng chuẩn
create_server() {
  local NAME=$1 PROJECT=$2 ENV=$3 OWNER=$4 COST_CENTER=$5

  docker run -d \
    --name "$NAME" \
    -p 0:80 \
    --label Name="$NAME" \
    --label Project="$PROJECT" \
    --label Environment="$ENV" \
    --label Owner="$OWNER" \
    --label CostCenter="$COST_CENTER" \
    nginx:alpine \
    sh -c "echo '$NAME' > /usr/share/nginx/html/index.html; nginx -g 'daemon off;'"

  echo "✅ $NAME [Project=$PROJECT, Env=$ENV, Owner=$OWNER]"
}

create_server "api-server-prod"   "e-commerce"     "production"  "team-backend"  "CC-001"
create_server "web-server-prod"   "e-commerce"     "production"  "team-frontend" "CC-001"
create_server "worker-prod"       "data-platform"  "production"  "team-data"     "CC-002"
create_server "reporting-server"  "internal-tools" "staging"     "team-devops"   "CC-003"
create_server "old-test-server"   "internal-tools" "development" "team-devops"   "CC-003"
```

### 1.2 — Kiểm tra tag compliance

```bash
echo "=== Kiểm tra tất cả containers có đủ 5 tags chuẩn ==="
REQUIRED_TAGS="Name Project Environment Owner CostCenter"
FAIL=0

for C in api-server-prod web-server-prod worker-prod reporting-server old-test-server; do
  MISSING=""
  for TAG in $REQUIRED_TAGS; do
    VALUE=$(docker inspect $C --format "{{index .Config.Labels \"$TAG\"}}")
    [ -z "$VALUE" ] && MISSING="$MISSING $TAG"
  done

  if [ -z "$MISSING" ]; then
    echo "  ✅ $C — đủ tags"
  else
    echo "  ❌ $C — thiếu:$MISSING"
    FAIL=$((FAIL+1))
  fi
done

echo ""
[ $FAIL -eq 0 ] && echo "Tag compliance: 100% ✅" || echo "Tag compliance: $FAIL servers thiếu tag ❌"
```

### 1.3 — Query tài nguyên theo tag (như Cloud console)

```bash
echo "=== Servers thuộc Project 'e-commerce' ==="
docker ps --filter "label=Project=e-commerce" \
  --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "=== Servers môi trường 'production' ==="
docker ps --filter "label=Environment=production" \
  --format "table {{.Names}}"

echo ""
echo "=== Servers của team-data ==="
docker ps --filter "label=Owner=team-data" \
  --format "table {{.Names}}\t{{.Status}}"
```

### 1.4 — Tạo bản đồ chi phí theo tag

```bash
python3 << 'EOF'
import subprocess, json

# Lấy danh sách containers và labels
result = subprocess.run(
    ["docker", "inspect",
     "api-server-prod", "web-server-prod", "worker-prod",
     "reporting-server", "old-test-server"],
    capture_output=True, text=True
)
containers = json.loads(result.stdout)

# Chi phí giả định theo instance type (giờ/tháng)
COST_MAP = {
    "api-server-prod":   59.90,
    "web-server-prod":   29.95,
    "worker-prod":       59.90,
    "reporting-server": 119.81,
    "old-test-server":   29.95,
}

# Phân bổ theo Project
from collections import defaultdict
by_project = defaultdict(float)
by_env = defaultdict(float)

for c in containers:
    name = c["Name"].strip("/")
    labels = c["Config"]["Labels"]
    cost = COST_MAP.get(name, 0)
    by_project[labels.get("Project", "unknown")] += cost
    by_env[labels.get("Environment", "unknown")] += cost

print("=== Chi phí theo Project ===")
for proj, cost in sorted(by_project.items(), key=lambda x: -x[1]):
    print(f"  {proj:20s}: ${cost:.2f}/tháng")

print("\n=== Chi phí theo Environment ===")
for env, cost in sorted(by_env.items(), key=lambda x: -x[1]):
    print(f"  {env:15s}: ${cost:.2f}/tháng")

print(f"\n  Tổng: ${sum(by_project.values()):.2f}/tháng")
EOF
```

---

## Tương đương trên Cloud

| Lab (Docker labels) | AWS | GCP | Azure |
|--------------------|-----|-----|-------|
| `--label Project=e-commerce` | Tag: `Project=e-commerce` | Label: `project=e-commerce` | Tag: `Project=e-commerce` |
| `docker ps --filter label=Project=X` | Cost Explorer → filter by tag | Billing → label filter | Cost Analysis → tag filter |
| Tag compliance check | AWS Config Rules | Organization Policy | Azure Policy |

---

## Câu hỏi

1. Điều gì xảy ra với chi phí nếu một team không gắn tag đúng chuẩn?
2. Chiến lược nào đảm bảo **tag consistency** khi team scale lên 50 engineers?
3. Nếu dùng Terraform/Ansible, làm sao tự động gắn tag cho mọi resource?
