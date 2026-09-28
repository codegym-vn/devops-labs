# Bước 2: Cấu Hình Security Groups Kiểm Soát Lưu Lượng

Trong bước này, bạn sẽ sử dụng **AWS CLI** để thiết lập hệ thống tường lửa ảo **Security Groups (SG)** bảo vệ máy chủ theo nguyên tắc **Least Privilege (Quyền tối thiểu)**.

---

## 1. Lý Thuyết: Security Groups & Kỹ Thuật Chaining

* **Security Group (Tường lửa cấp Instance):** Hoạt động như một lá chắn ảo bao quanh từng máy ảo EC2.
* **Đặc tính Stateful:** Nếu bạn cho phép lưu lượng đi vào ở cổng 80 (Inbound), lưu lượng phản hồi (Response) sẽ tự động được phép đi ra (Outbound) mà không cần cấu hình thêm quy tắc Outbound.
* **Mặc định:**
  * **Inbound:** Chặn tất cả (`Deny all`). Bạn phải chỉ định rõ mở cổng nào.
  * **Outbound:** Mở tất cả (`Allow all`).
* **Kỹ thuật Chaining (Tham chiếu chéo giữa các SG):**
  * Trong mô hình bảo mật chuẩn doanh nghiệp, bạn **tuyệt đối không mở cổng Database (5432/3306) ra `0.0.0.0/0`**, thậm chí không nên mở theo IP tĩnh (vì IP máy chủ có thể thay đổi khi Auto-scaling).
  * Thay vào đó, bạn cấu hình nguồn (Source) của `db-sg` chính là `web-sg`. Điều này đảm bảo: **Chỉ những máy ảo nào mang nhãn `web-sg` mới được phép nói chuyện với Database!**

```
Internet (0.0.0.0/0)
       │
       ▼ (Port 80/443)
┌──────────────┐
│    web-sg    │
└──────┬───────┘
       │
       ▼ (Port 5432 - Source: web-sg)
┌──────────────┐
│    db-sg     │
└──────────────┘
```

---

## 2. Thực Hành

Trước tiên, hãy tải lại các biến môi trường đã lưu ở Bước 1:

```bash
source /tmp/lab-env.sh
echo "VPC hiện tại: $VPC_ID"
```{{exec}}

---

### 2.1 — Tạo Security Group cho Web Server (`web-sg`)

Tạo một nhóm bảo mật mới đặt trong VPC của bạn:

```bash
WEB_SG_ID=$(aws ec2 create-security-group \
  --group-name "web-sg" \
  --description "Security group cho Web Servers cong khai" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=web-sg}]' \
  --query 'GroupId' \
  --output text)

echo "✅ Đã tạo web-sg: $WEB_SG_ID"
echo "WEB_SG_ID=$WEB_SG_ID" >> /tmp/lab-env.sh
```{{exec}}

---

### 2.2 — Mở Cổng HTTP (80) & SSH (22) Cho Web Server

1. **Mở HTTP (80):** Cho phép toàn bộ người dùng Internet (`0.0.0.0/0`) truy cập website:
   ```bash
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG_ID \
     --protocol tcp \
     --port 80 \
     --cidr 0.0.0.0/0
   ```{{exec}}

2. **Mở SSH (22):** Theo nguyên tắc Least Privilege, chỉ cho phép kết nối SSH từ dải IP nội bộ VPC (`10.0.0.0/16`) thay vì mở ra toàn cầu:
   ```bash
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG_ID \
     --protocol tcp \
     --port 22 \
     --cidr 10.0.0.0/16
   ```{{exec}}

---

### 2.3 — Tạo Security Group cho Database Server (`db-sg`)

Tạo nhóm bảo mật riêng cho tầng cơ sở dữ liệu:

```bash
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name "db-sg" \
  --description "Security group cho Database Servers noi bo" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=db-sg}]' \
  --query 'GroupId' \
  --output text)

echo "✅ Đã tạo db-sg: $DB_SG_ID"
echo "DB_SG_ID=$DB_SG_ID" >> /tmp/lab-env.sh
```{{exec}}

---

### 2.4 — Thiết Lập Liên Kết Chaining: Chỉ Cho Phép `web-sg` Truy Cập Database

Sử dụng tham số `--source-group` để ủy quyền kết nối cổng PostgreSQL (`5432`) tới đích danh `web-sg`:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $WEB_SG_ID

echo "✅ Đã liên kết: db-sg chỉ chấp nhận traffic từ web-sg!"
```{{exec}}

Kiểm tra lại toàn bộ quy tắc Inbound của `db-sg`:

```bash
aws ec2 describe-security-groups --group-ids $DB_SG_ID --output table
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP]
> Hoàn thành phần thực hành trên trước khi làm bài tập này.

**Yêu cầu:** Môi trường Production chuẩn bị kích hoạt chứng chỉ số SSL/TLS.
* Hãy thêm quy tắc Inbound mở cổng **HTTPS (Port 443)** cho giao thức `tcp` từ mọi địa chỉ IP (`0.0.0.0/0`) vào nhóm bảo mật `web-sg` (`$WEB_SG_ID`).

**Gợi ý lệnh:**
* Dùng lệnh `aws ec2 authorize-security-group-ingress` tương tự như cách mở cổng 80 ở mục **2.2**, thay đổi `--port 443`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
