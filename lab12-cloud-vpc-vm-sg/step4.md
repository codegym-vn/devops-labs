# Bước 4: Kiểm thử hạ tầng và dọn dẹp

## Lý thuyết

**Cleanup là kỹ năng bắt buộc** — tài nguyên Cloud không dùng vẫn tính phí theo giờ:

| Tài nguyên quên xóa | Chi phí ước tính |
|--------------------|--------------------|
| VM (t3.medium) idle | ~$30/tháng |
| Load Balancer | ~$20/tháng |
| Static IP chưa gắn | ~$3.6/tháng |

Trong lab: dọn dẹp bằng `docker stop/rm` và `docker network rm`.

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 4.1 — Kiểm thử end-to-end

```bash
echo "=== Kiểm thử toàn bộ hạ tầng ==="

# 1. VPC (networks)
echo "1. Networks (VPCs):"
docker network ls | grep -E "public-subnet|private-subnet|devops-vpc"

# 2. Instances (containers)
echo "2. Instances (Containers):"
docker ps --filter "label=Environment=production" \
  --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"

# 3. Security rules (UFW)
echo "3. Security rules:"
ufw status | grep -E "80|8080|8081|22|ALLOW"

# 4. HTTP test
echo "4. HTTP test:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081)
echo "   Web server port 8081: HTTP $HTTP_CODE $([ $HTTP_CODE = "200" ] && echo  || echo )"

# 5. Isolation test (private subnet không public)
echo "5. DB isolation:"
nc -z -w2 localhost 5432 2>/dev/null && echo "   Port 5432: OPEN " || echo "   Port 5432: BLOCKED "
```

### 4.2 — Tổng kết kiến trúc

```bash
cat << 'EOF'
╔══════════════════════════════════════════════════════╗
║         HẠ TẦNG MẠNG CLOUD — LAB 12                ║
╠══════════════════════════════════════════════════════╣
║  VPC (devops-vpc): 10.0.0.0/16                       ║
║    ├── Public Subnet: 10.0.1.0/24                    ║
║    │     └── web-server-1 (10.0.1.10)                ║
║    │           SG: port 80   port 22 (VPC)       ║
║    │           Internet: port 8081 public             ║
║    └── Private Subnet: 10.0.2.0/24                   ║
║          └── db-server-1 (10.0.2.10)                 ║
║                SG: port 5432 (VPC only)            ║
║                Internet: BLOCKED                   ║
╚══════════════════════════════════════════════════════╝
EOF
```

### 4.3 — Dọn dẹp

```bash
echo "=== Dọn dẹp tài nguyên ==="

# Xóa Compute Instances (containers)
for C in web-server-1 db-server-1 web-server; do
  docker stop $C 2>/dev/null && docker rm $C 2>/dev/null && echo " Xóa container $C"
done

# Xóa Networks (VPC + Subnets)
for N in public-subnet private-subnet devops-vpc; do
  docker network rm $N 2>/dev/null && echo " Xóa network $N"
done

# Reset Security rules
ufw delete allow 80/tcp 2>/dev/null
ufw delete allow 8080/tcp 2>/dev/null
ufw delete allow 8081/tcp 2>/dev/null
ufw --force disable 2>/dev/null

echo ""
echo "Xác nhận không còn gì:"
docker ps -a | grep -E "web-server|db-server" || echo " Không còn container nào"
docker network ls | grep -E "public-subnet|private-subnet|devops-vpc" || echo " Không còn network nào"
```

---

## Tổng kết

```
Bước 1: VPC (docker network) → Public Subnet + Private Subnet
Bước 2: Security Group (UFW) → port 80 public, port 5432 VPC only
Bước 3: Compute Instance (container) → web server + db server
Bước 4: End-to-end test + Cleanup

Trên Cloud thật: thay docker → aws/gcloud/az CLI
Concepts giống nhau 100%
```

---

##  Bài tập

> Hoàn thành cleanup trên trước khi làm bài tập này.

**Yêu cầu:** Trước khi tắt lab, kỹ sư Cloud thường lưu lại trạng thái hạ tầng để audit.

Viết lệnh (hoặc script ngắn) tạo file `/tmp/infra-snapshot.json` chứa:
```json
{
  "timestamp": "<thời gian hiện tại>",
  "containers": ["<danh sách tên containers đã xóa>"],
  "networks": ["<danh sách networks đã xóa>"],
  "status": "cleaned"
}
```

**Gợi ý khi bí:**
- `date -u +"%Y-%m-%dT%H:%M:%SZ"` lấy timestamp
- `python3 -c "import json; ..."` để tạo JSON
- File phải hợp lệ JSON: `python3 -m json.tool /tmp/infra-snapshot.json`

> Nhấn **Check** khi hoàn thành.
