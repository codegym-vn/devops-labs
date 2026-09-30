# Bước 3: Khởi Tạo Terraform Workspaces & Triển Khai Môi Trường Dev

Trong bước này, bạn sẽ làm quen với cơ chế quản lý đa môi trường bằng **Terraform Workspaces**, cấu hình các file tham số môi trường (`environments/dev.tfvars`, `environments/prod.tfvars`) và triển khai toàn bộ cụm hạ tầng cho môi trường **Development**.

---

## 1. Lý Thuyết: Cơ Chế Hoạt Động Của Terraform Workspaces

### 1.1 — Workspaces Là Gì?
Mỗi Workspace là một **không gian làm việc độc lập** với file trạng thái (`tfstate`) riêng biệt, nhưng dùng chung một bộ mã nguồn HCL duy nhất:
* Mặc định khi khởi tạo dự án, bạn luôn ở Workspace mang tên `default`.
* Khi bạn tạo một Workspace mới tên là `dev`, Terraform sẽ tự động tạo thư mục cách ly:
  `terraform.tfstate.d/dev/terraform.tfstate`
* Khi bạn chuyển sang Workspace `prod`, Terraform sẽ đọc và ghi vào:
  `terraform.tfstate.d/prod/terraform.tfstate`
→ **Lợi ích cốt lõi:** Bạn có thể thoải mái thử nghiệm, phá hủy môi trường `dev` mà không bao giờ sợ ảnh hưởng hay ghi đè lên môi trường `prod`!

### 1.2 — Quản Lý Biến Đa Môi Trường Với File `.tfvars`
Thay vì gán cứng thông số trong code, chúng ta tạo các file biến riêng biệt cho từng môi trường:
* **Dev:** Dùng tài nguyên nhỏ để tiết kiệm chi phí (`t2.micro`, dải mạng `10.10.0.0/16`).
* **Prod:** Dùng tài nguyên lớn hơn để đảm bảo hiệu năng (`t2.small`, dải mạng `10.20.0.0/16`).

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-workspaces-lab`.

### 2.1 — Tạo các file cấu hình môi trường (`.tfvars`)

Tạo thư mục `environments`:

```bash
mkdir -p environments
```{{exec}}

Tạo file thông số cho môi trường **Development** (`environments/dev.tfvars`):

```bash
cat << 'EOF' > environments/dev.tfvars
env_name           = "dev"
vpc_cidr           = "10.10.0.0/16"
public_subnet_cidr = "10.10.1.0/24"
instance_type      = "t2.micro"
EOF
```{{exec}}

Tạo file thông số cho môi trường **Production** (`environments/prod.tfvars`):

```bash
cat << 'EOF' > environments/prod.tfvars
env_name           = "prod"
vpc_cidr           = "10.20.0.0/16"
public_subnet_cidr = "10.20.1.0/24"
instance_type      = "t2.small"
EOF
```{{exec}}

---

### 2.2 — Làm quen với các lệnh điều khiển Workspace

1. **Liệt kê các workspace hiện có:**
   ```bash
   terraform workspace list
   ```{{exec}}
   *(Dấu `* default` cho biết bạn đang ở không gian mặc định).*

2. **Khởi tạo và chuyển sang Workspace `dev`:**
   ```bash
   terraform workspace new dev
   ```{{exec}}
   *Thông báo: `Created and switched to workspace "dev"!`*

3. **Kiểm tra Workspace đang hoạt động:**
   ```bash
   terraform workspace show
   ```{{exec}}

---

### 2.3 — Lập kế hoạch và triển khai hạ tầng cho môi trường Dev

Lập kế hoạch thực thi với cờ `-var-file`:

```bash
terraform plan -var-file=environments/dev.tfvars -out=dev.tfplan
```{{exec}}

Quan sát đầu ra: Toàn bộ tên tài nguyên đều được gắn tiền tố `dev-*` (như `dev-vpc`, `dev-public-subnet`, `dev-web-sg`, `dev-web-server`) và sử dụng dải IP `10.10.0.0/16`.

Áp dụng kế hoạch:

```bash
terraform apply dev.tfplan
```{{exec}}

---

### 2.4 — Khám phá sự cô lập trạng thái & đối chứng AWS CLI

1. **Kiểm tra cấu trúc thư mục trạng thái:**
   Nhìn vào cây thư mục bên trái của Theia IDE, bạn sẽ thấy thư mục `terraform.tfstate.d/dev/` xuất hiện chứa file `terraform.tfstate` của riêng môi trường dev.

2. **Xem danh sách tài nguyên của dev:**
   ```bash
   terraform state list
   ```{{exec}}

3. **Đối chứng độc lập bằng AWS CLI:**
   Kiểm tra VPC và máy ảo của dev trên LocalStack:
   ```bash
   aws ec2 describe-vpcs \
     --filters "Name=tag:Name,Values=dev-vpc" \
     --query "Vpcs[0].[VpcId,CidrBlock,Tags[?Key=='Name'].Value|[0]]" \
     --output table
   ```{{exec}}

   ```bash
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=dev-web-server" \
     --query "Reservations[0].Instances[0].[InstanceId,InstanceType,PrivateIpAddress]" \
     --output table
   ```{{exec}}

Máy ảo `dev-web-server` loại `t2.micro` đang chạy trong dải mạng `10.10.1.x`!

---

## 3. Bài Tập Thử Thách

1. Chạy lệnh `terraform output` để xem lại toàn bộ thông tin xuất ra của môi trường `dev`.
2. Kiểm tra xem Security Group `dev-web-sg` có đang thuộc đúng VPC của dev hay không bằng lệnh:
   ```bash
   aws ec2 describe-security-groups --filters "Name=group-name,Values=dev-web-sg" --output table
   ```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
