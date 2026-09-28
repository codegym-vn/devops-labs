# 🏆 Chúc mừng! Bạn đã hoàn thành Lab: Xây Dựng Mạng VPC & Security Groups trên AWS

Bạn vừa tự tay xây dựng một hệ thống mạng Cloud cô lập hoàn chỉnh bằng **AWS CLI** trên môi trường giả lập **LocalStack**!

---

## 1. Tóm Tắt Toàn Bộ Kiến Trúc Đã Xây Dựng

```text
 1. Nền Móng Mạng (VPC & Subnets):
    VPC (10.0.0.0/16) ──┬── Public Subnet (10.0.1.0/24) ──► Internet Gateway (IGW)
                        └── Private Subnet (10.0.2.0/24) ─► Cách ly hoàn toàn với Internet

 2. Tường Lửa Đa Tầng (Security Groups):
    • web-sg: Mở Inbound Port 80 & 443 cho 0.0.0.0/0, Port 22 cho 10.0.0.0/16
    • db-sg:  Mở Inbound Port 5432 CHỈ TỪ nguồn web-sg (Chaining Security Groups)

 3. Máy Ảo EC2 & Xác Thực:
    • Khởi tạo cặp khóa SSH Key Pair (devops-key)
    • Khởi chạy web-server-1, web-server-2 và db-server-1 vào đúng Subnet quy định

 4. Quản Lý Vòng Đời & Dọn Dẹp (FinOps):
    • Quản lý trạng thái Stop/Start máy ảo
    • Hủy (Terminate) các instance theo đúng thứ tự phụ thuộc
```

---

## 2. Bảng Tra Cứu Lệnh AWS CLI (Cheat Sheet)

### 2.1 — Quản lý Mạng VPC & Subnet
```bash
# Tạo VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Tạo Subnet
aws ec2 create-subnet --vpc-id <VPC_ID> --cidr-block 10.0.1.0/24

# Tạo và gắn Internet Gateway
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id <VPC_ID> --internet-gateway-id <IGW_ID>

# Thêm route ra Internet cho Route Table
aws ec2 create-route --route-table-id <RT_ID> --destination-cidr-block 0.0.0.0/0 --gateway-id <IGW_ID>

# Liên kết Route Table với Subnet
aws ec2 associate-route-table --subnet-id <SUBNET_ID> --route-table-id <RT_ID>
```

### 2.2 — Quản lý Security Groups
```bash
# Tạo Security Group
aws ec2 create-security-group --group-name "web-sg" --description "Web SG" --vpc-id <VPC_ID>

# Mở Inbound rule từ IP
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 80 --cidr 0.0.0.0/0

# Mở Inbound rule tham chiếu Security Group khác (Chaining)
aws ec2 authorize-security-group-ingress --group-id <DB_SG_ID> --protocol tcp --port 5432 --source-group <WEB_SG_ID>
```

### 2.3 — Quản lý Máy Ảo EC2
```bash
# Tạo SSH Key Pair
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem

# Khởi chạy EC2 instance
aws ec2 run-instances --image-id <AMI_ID> --instance-type t2.micro --key-name my-key \
  --subnet-id <SUBNET_ID> --security-group-ids <SG_ID>

# Dừng / Khởi động / Hủy máy ảo
aws ec2 stop-instances --instance-ids <INST_ID>
aws ec2 start-instances --instance-ids <INST_ID>
aws ec2 terminate-instances --instance-ids <INST_ID>
```

---

## 3. Câu Hỏi Phỏng Vấn Tuyển Dụng Thường Gặp

1. **Sự khác nhau giữa Security Group và Network ACL (NACL) là gì?**
   * *Trả lời:* Security Group hoạt động ở tầng **Instance**, có tính chất **Stateful** (cho phép inbound thì outbound tự mở), và chỉ có quy tắc ALLOW. Network ACL hoạt động ở tầng **Subnet**, có tính chất **Stateless** (phải cấu hình cả inbound lẫn outbound), và hỗ trợ cả rule ALLOW lẫn DENY theo thứ tự ưu tiên (Rule number).
2. **Làm thế nào để các máy ảo trong Private Subnet tải bản vá phần mềm từ Internet mà bên ngoài vẫn không truy cập được vào nó?**
   * *Trả lời:* Triển khai một **NAT Gateway** (hoặc NAT Instance) đặt trong **Public Subnet**, sau đó cấu hình Route Table của Private Subnet trỏ `0.0.0.0/0` hướng về NAT Gateway đó.
