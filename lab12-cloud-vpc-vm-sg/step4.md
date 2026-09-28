# Bước 4: Kiểm Thử Toàn Bộ Hạ Tầng & Quy Trình Dọn Dẹp (Cleanup)

Trong bước cuối cùng, bạn sẽ kiểm tra bức tranh tổng thể của hạ tầng Cloud đã xây dựng, thực hành quản lý trạng thái vòng đời máy ảo và làm chủ **quy trình dọn dẹp tài nguyên (Resource Cleanup)** — kỹ năng sống còn của kỹ sư Cloud/DevOps để tránh lãng phí ngân sách.

---

## 1. Lý Thuyết: Phân Tích Luồng Traffic & Thứ Tự Phụ Thuộc Tài Nguyên

### 1.1 — Luồng gói tin (Traffic Flow)
* **Từ ngoài Internet vào Web Server:**
  $$\text{User} \longrightarrow \text{IGW} \longrightarrow \text{Route Table (0.0.0.0/0)} \longrightarrow \text{Public Subnet} \longrightarrow \text{web-sg (Port 80/443)} \longrightarrow \text{web-server-1}$$
* **Từ ngoài Internet vào Database Server:**
  $$\text{Hacker / Scanner} \longrightarrow \text{Không thể tìm thấy đường dẫn (Private Subnet không có route ra IGW)} \mathrel{\mathbf{\times}} \text{Bị chặn}$$
* **Từ Web Server sang Database Server:**
  $$\text{web-server-1} \longrightarrow \text{Giao tiếp nội bộ VPC} \longrightarrow \text{db-sg (Kiểm tra source-group: đúng là web-sg)} \longrightarrow \text{Cho phép kết nối port 5432!}$$

### 1.2 — Thứ tự phụ thuộc khi dọn dẹp tài nguyên (Dependency Order)
Trên Cloud, bạn **không thể** xóa bừa bãi một tài nguyên cha nếu các tài nguyên con bên trong nó vẫn còn tồn tại. Thứ tự dọn dẹp chuẩn:
1. **Hủy máy ảo (Terminate Instances):** Giải phóng IP và card mạng gắn với Subnet.
2. **Xóa Security Groups:** Chỉ xóa được khi không còn instance nào gán vào nó.
3. **Tháo rời & Xóa Internet Gateway (Detach & Delete IGW).**
4. **Xóa các Subnets.**
5. **Xóa VPC.**

---

## 2. Thực Hành

Tải lại các biến môi trường:

```bash
source /tmp/lab-env.sh
```{{exec}}

---

### 4.1 — Kiểm Tra Toàn Diện Bức Tranh Hạ Tầng

Chạy đoạn script tổng hợp để trích xuất báo cáo hiện trạng tài nguyên:

```bash
echo "=========================================================="
echo "           BÁO CÁO TỔNG QUAN HẠ TẦNG CLOUD LAB 12        "
echo "=========================================================="

echo "1. VPC:"
aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value | [0]]' --output table

echo "2. Subnets:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].[SubnetId,CidrBlock,Tags[?Key==`Name`].Value | [0]]' --output table

echo "3. Security Groups & Quy tắc Inbound:"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[].[GroupName,GroupId]' --output table

echo "4. Các Máy Ảo EC2 Đang Chạy:"
aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value | [0],State.Name,PrivateIpAddress]' --output table
```{{exec}}

---

### 4.2 — Quản Lý Vòng Đời Máy Ảo: Stop và Start Instance

Trong thực tế (FinOps), các máy ảo thuộc môi trường Development hoặc Staging nên được tắt ngoài giờ hành chính để tiết kiệm ~60% chi phí.

1. **Tạm dừng máy ảo Web Server:**
   ```bash
   aws ec2 stop-instances --instance-ids $WEB_INST_ID
   echo "⏳ Đang chuyển trạng thái sang stopped..."
   aws ec2 wait instance-stopped --instance-ids $WEB_INST_ID
   echo "✅ Instance $WEB_INST_ID đã dừng (stopped) thành công!"
   ```{{exec}}

2. **Khởi động lại máy ảo:**
   ```bash
   aws ec2 start-instances --instance-ids $WEB_INST_ID
   echo "⏳ Đang khởi động lại..."
   aws ec2 wait instance-running --instance-ids $WEB_INST_ID
   echo "✅ Instance $WEB_INST_ID đã hoạt động (running) trở lại!"
   ```{{exec}}

---

## 3. Bài Tập Thử Thách: Dọn Dẹp Tài Nguyên

> [!WARNING]
> Trên môi trường Cloud thật (AWS/GCP/Azure), nếu bạn quên xóa máy ảo hoặc tài nguyên không sử dụng, hóa đơn tính phí hàng tháng sẽ tiếp tục tăng ngay cả khi bạn không truy cập vào server!

**Yêu cầu:** Hãy thực hiện dọn dẹp cụm máy ảo EC2 trong VPC để hoàn thành bài lab:
1. Lấy danh sách toàn bộ `InstanceId` đang chạy trong VPC `$VPC_ID`.
2. Gửi lệnh hủy (`terminate-instances`) cho tất cả các máy ảo vừa tạo (`web-server-1`, `db-server-1`, và `web-server-2`).

```bash
# Lấy danh sách toàn bộ Instance IDs trong VPC và thực hiện Terminate
ALL_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo "Đang hủy các instances: $ALL_INSTANCES"
aws ec2 terminate-instances --instance-ids $ALL_INSTANCES
```{{exec}}

Kiểm tra lại trạng thái để thấy các máy ảo chuyển sang `shutting-down` hoặc `terminated`:

```bash
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Reservations[].Instances[].[InstanceId,State.Name]" \
  --output table
```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và xác nhận hoàn thành bài lab!
