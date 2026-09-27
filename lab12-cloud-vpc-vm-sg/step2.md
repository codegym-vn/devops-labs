# Bước 2: Cấu hình Security Groups

## Lý thuyết

**Security Group** là tường lửa cấp instance — kiểm soát traffic vào/ra từng server cụ thể.

Đặc điểm quan trọng:
- **Stateful**: cho phép port 80 vào → response tự động được phép ra (không cần khai báo outbound)
- **Mặc định chặn tất cả** inbound — chỉ mở những gì cần thiết
- **Chỉ có ALLOW** — không có DENY rule (khác với tường lửa truyền thống)

```
Internet ──→ [Security Group] ──→ Server
               ✅ Port 80 (HTTP)
               ✅ Port 22 (SSH, từ IP riêng)
               ❌ Tất cả còn lại
```

**Nguyên tắc Least Privilege**: chỉ mở đúng port cần thiết, đúng nguồn cần thiết.

Trong Linux, Security Group = **UFW rules** (đã học Lab 3).

---

## Thực hành

```bash
source /tmp/lab-env.sh
```

### 2.1 — Xem trạng thái firewall hiện tại

```bash
ufw status verbose
```

### 2.2 — Thiết lập rule cho Web Server (Public Subnet)

```bash
# Web server: chỉ mở HTTP (80) và SSH từ IP cụ thể
# Tương đương Security Group trong Cloud

# Bật UFW nếu chưa bật
echo "y" | ufw enable 2>/dev/null || true

# Mở port HTTP cho tất cả (public web server)
ufw allow 80/tcp comment "HTTP - web server public"
ufw allow 8080/tcp comment "HTTP alt - lab testing"

# Mở SSH chỉ từ IP cụ thể (nguyên tắc Least Privilege)
# Trong thực tế: thay 0.0.0.0/0 bằng IP của bạn
ufw allow from 10.0.0.0/16 to any port 22 comment "SSH - internal VPC only"

# Chặn tất cả traffic khác vào
ufw default deny incoming
ufw default allow outgoing

echo "=== Security Group Web Server ==="
ufw status numbered
```

### 2.3 — Thiết lập rule cho DB Server (Private Subnet)

```bash
# DB server: chỉ cho phép kết nối từ trong VPC
# KHÔNG mở port ra ngoài Internet

ufw allow from 10.0.1.0/24 to any port 5432 comment "PostgreSQL - public subnet only"
ufw allow from 10.0.2.0/24 to any port 5432 comment "PostgreSQL - private subnet"
# Port 22 KHÔNG được phép từ Internet — chỉ qua bastion host

echo "=== Security Group DB Server ==="
echo "Port 5432: chỉ từ 10.0.1.0/24 và 10.0.2.0/24"
echo "Port 22: KHÔNG mở ra Internet"
```

### 2.4 — Kiểm thử: port đúng/sai

```bash
# Port 8080 phải OPEN (HTTP đã cho phép)
echo -n "Port 8080 (HTTP): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 && echo " ✅ OPEN"

# Port 3306 phải BLOCKED (MySQL chưa khai báo)
echo -n "Port 3306 (MySQL không khai báo): "
nc -z -w2 localhost 3306 2>/dev/null && echo "OPEN ⚠️" || echo "BLOCKED ✅"
```

### 2.5 — Audit: kiểm tra rule thừa

```bash
# Giả sử ai đó vô tình mở port 8443
ufw allow 8443/tcp comment "test - sẽ xóa"
echo "Trước khi audit:"
ufw status numbered | grep 8443

# Phát hiện → thu hồi ngay
ufw delete allow 8443/tcp
echo "✅ Đã thu hồi rule không cần thiết (port 8443)"
```

---

## Tương đương trên các Cloud Provider

| Rule trong lab | AWS | GCP | Azure |
|----------------|-----|-----|-------|
| `ufw allow 80/tcp` | Inbound rule: TCP 80 | Firewall rule: allow tcp:80 | NSG inbound: TCP 80 |
| `ufw allow from 10.0.1.0/24 port 5432` | SG source: 10.0.1.0/24, port 5432 | Target tag firewall rule | NSG source CIDR |
| `ufw default deny incoming` | SG mặc định chặn tất cả | Implicit deny | Default deny |

---

## Câu hỏi

1. Security Group "stateful" nghĩa là gì? Lợi thế so với tường lửa stateless?
2. Nếu không khai báo Outbound rule — điều gì xảy ra với traffic đi ra?
3. Tại sao SSH (port 22) không nên mở cho `0.0.0.0/0`?

---

## 🎯 Bài tập

> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Hệ thống sẽ triển khai HTTPS. Mở port 443 cho public, nhưng chỉ cho traffic từ network `10.0.0.0/8` (không phải toàn bộ internet).

Ngoài ra, thêm rule rate-limit: chỉ cho phép port 8443 từ địa chỉ `172.16.0.0/12` (internal corporate network).

**Kết quả cần đạt:**
- Port 443: chỉ từ `10.0.0.0/8`
- Port 8443: chỉ từ `172.16.0.0/12`
- Hai rule phải có comment mô tả mục đích

**Gợi ý khi bí:**
- `ufw allow from <CIDR> to any port <PORT>` — xem lại phần 2.2
- `comment "mô tả"` thêm vào cuối lệnh ufw
- `ufw status numbered` để kiểm tra sau khi thêm

> Nhấn **Check** khi hoàn thành.
