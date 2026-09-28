# Bước 1: Tạo VPC, Subnet và Internet Gateway với AWS CLI

Trong bước này, bạn sẽ sử dụng **AWS CLI** để khởi tạo nền móng hạ tầng mạng: một VPC cô lập, phân vùng thành Public/Private Subnet và kích hoạt đường ra Internet qua Internet Gateway.

---

## 1. Lý Thuyết: Hạ Tầng Mạng Ảo (AWS VPC & Subnet)

* **VPC (Virtual Private Cloud):** Một mạng riêng ảo độc lập trên hạ tầng đám mây. Bạn toàn quyền kiểm soát dải địa chỉ IP (CIDR block, ví dụ `10.0.0.0/16` cung cấp 65,536 địa chỉ IP).
* **Subnet:** Phân chia dải IP của VPC thành các mạng con nhỏ hơn:
  * **Public Subnet:** Chứa các dịch vụ cần giao tiếp với người dùng bên ngoài Internet (Web server, Load Balancer).
  * **Private Subnet:** Cô lập hoàn toàn với Internet, chỉ giao tiếp nội bộ bên trong VPC (Database, Redis Cache).
* **Internet Gateway (IGW) & Route Table:** Một Subnet **chỉ trở thành Public** khi bảng định tuyến (Route Table) gắn với nó có một quy tắc (route): `0.0.0.0/0` trỏ tới Internet Gateway!

---

## 2. Thực Hành

### 1.1 — Khởi tạo VPC (`devops-vpc`)

Tạo một VPC mới với dải địa chỉ `10.0.0.0/16` và gắn thẻ tag định danh `Name=devops-vpc`:

```bash
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=devops-vpc}]' \
  --query 'Vpc.VpcId' \
  --output text)

echo "✅ Đã tạo VPC thành công với ID: $VPC_ID"
echo "VPC_ID=$VPC_ID" > /tmp/lab-env.sh
```{{exec}}

Kiểm tra lại thông tin VPC vừa tạo:

```bash
aws ec2 describe-vpcs --vpc-ids $VPC_ID --output table
```{{exec}}

---

### 1.2 — Tạo Public Subnet và Private Subnet

Chia nhỏ VPC thành 2 mạng con:

* **Public Subnet:** `10.0.1.0/24` (Dành cho Web Server).
* **Private Subnet:** `10.0.2.0/24` (Dành cho Database Server).

Tạo **Public Subnet**:

```bash
PUB_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "✅ Đã tạo Public Subnet: $PUB_SUBNET_ID"
echo "PUB_SUBNET_ID=$PUB_SUBNET_ID" >> /tmp/lab-env.sh
```{{exec}}

Tạo **Private Subnet**:

```bash
PRIV_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "✅ Đã tạo Private Subnet: $PRIV_SUBNET_ID"
echo "PRIV_SUBNET_ID=$PRIV_SUBNET_ID" >> /tmp/lab-env.sh
```{{exec}}

---

### 1.3 — Tạo Internet Gateway (IGW) & Gắn vào VPC

Mặc định, VPC mới hoàn toàn cách ly với thế giới bên ngoài. Để Public Subnet có thể kết nối Internet, ta cần gắn một cổng **Internet Gateway**:

```bash
# 1. Tạo Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=devops-igw}]' \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

echo "✅ Đã tạo Internet Gateway: $IGW_ID"
echo "IGW_ID=$IGW_ID" >> /tmp/lab-env.sh

# 2. Gắn (Attach) IGW vào VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID

echo "✅ Đã gắn IGW $IGW_ID vào VPC $VPC_ID"
```{{exec}}

---

### 1.4 — Tạo Route Table & Định Tuyến Ra Internet Cho Public Subnet

Để biến `public-subnet` thành subnet công khai thực thụ:
1. Tạo một Route Table tùy chỉnh.
2. Thêm tuyến đường (Route) dẫn mọi lưu lượng đi ra ngoài (`0.0.0.0/0`) hướng tới IGW.
3. Liên kết (Associate) Route Table này với `public-subnet`.

```bash
# 1. Tạo Route Table
RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]' \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "✅ Đã tạo Route Table: $RT_ID"
echo "RT_ID=$RT_ID" >> /tmp/lab-env.sh

# 2. Thêm route dẫn 0.0.0.0/0 ra Internet Gateway
aws ec2 create-route \
  --route-table-id $RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# 3. Liên kết Route Table với Public Subnet
aws ec2 associate-route-table \
  --subnet-id $PUB_SUBNET_ID \
  --route-table-id $RT_ID

echo "✅ Đã cấu hình Public Subnet định tuyến ra Internet thành công!"
```{{exec}}

---

## 3. Bài Tập Thử Thách

> [!TIP]
> Hãy hoàn thành các thao tác trên trước khi làm bài tập này.

**Yêu cầu:** Kiến trúc cần bổ sung thêm một Subnet chuyên dụng cho cụm sao lưu cơ sở dữ liệu:
1. Tạo một Subnet mới trong VPC `$VPC_ID` với:
   * CIDR Block: `10.0.3.0/24`
   * Tag: `Key=Name,Value=db-subnet`
2. Lưu `SubnetId` của subnet này vào biến và kiểm tra lại bằng lệnh `aws ec2 describe-subnets`.

**Gợi ý:**
* Tương tự lệnh ở mục **1.2**, chỉ cần thay đổi giá trị CIDR và Tag Name.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
