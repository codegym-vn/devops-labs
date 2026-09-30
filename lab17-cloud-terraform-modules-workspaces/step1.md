# Bước 1: Thiết Kế & Đóng Gói Child Module Mạng (modules/vpc)

Trong bước đầu tiên, bạn sẽ thiết lập cấu trúc nền tảng cho dự án và đóng gói toàn bộ hạ tầng mạng (VPC, Subnet, Internet Gateway, Route Table) thành một **Child Module** độc lập, chuẩn hóa hợp đồng giao tiếp (Contract) qua biến đầu vào và giá trị đầu ra.

---

## 1. Lý Thuyết: Giải Phẫu Một Terraform Child Module

### 1.1 — Khái Niệm Module
* Trong Terraform, bất kỳ thư mục nào chứa các file `.tf` đều được gọi là một **Module**.
* Thư mục gốc nơi bạn chạy lệnh `terraform init/apply` được gọi là **Root Module**.
* Các module con nằm trong các thư mục con hoặc được tải về từ Git/Registry được gọi là **Child Modules**.

### 1.2 — Nguyên Tắc Đóng Gói Chuẩn Hóa
Một Child Module chuẩn mực luôn tuân theo bộ 3 file kinh điển:

```text
modules/vpc/
├── variables.tf   👉 Định nghĩa các tham số ĐẦU VÀO (Inputs) mà Root module phải truyền vào
├── main.tf        👉 Khai báo logic khởi tạo các tài nguyên (Resources)
└── outputs.tf     👉 Định nghĩa các giá trị ĐẦU RA (Outputs) để các module khác sử dụng
```

> [!IMPORTANT]
> **Quy tắc đặt tên động:** Bên trong Child Module, tuyệt đối không gán cứng tên tài nguyên (như `Name = "devops-vpc"`). Hãy sử dụng biến tiền tố (ví dụ: `Name = "${var.env_name}-vpc"`) để khi triển khai sang môi trường khác (`dev`, `prod`), tên tài nguyên sẽ tự động biến đổi mà không bị trùng lặp!

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục làm việc chính:

```bash
mkdir -p /root/terraform-workspaces-lab && cd /root/terraform-workspaces-lab
```{{exec}}

### 2.1 — Khởi tạo cấu hình phiên bản & Provider cho Root Module

Tạo file `versions.tf` ở thư mục gốc:

```bash
cat << 'EOF' > versions.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
```{{exec}}

Tạo file `provider.tf` ở thư mục gốc trỏ tới LocalStack:

```bash
cat << 'EOF' > provider.tf
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
EOF
```{{exec}}

---

### 2.2 — Khởi tạo thư mục và biến đầu vào cho Child Module (`modules/vpc`)

Tạo thư mục con cho module mạng:

```bash
mkdir -p modules/vpc
```{{exec}}

Định nghĩa biến đầu vào tại `modules/vpc/variables.tf`:

```bash
cat << 'EOF' > modules/vpc/variables.tf
variable "env_name" {
  description = "Tên môi trường (dev/prod) để gán nhãn nhận diện"
  type        = string
}

variable "vpc_cidr" {
  description = "Dải CIDR của VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Dải CIDR của Public Subnet"
  type        = string
}
EOF
```{{exec}}

---

### 2.3 — Lập trình tài nguyên mạng bên trong Child Module (`modules/vpc/main.tf`)

Viết logic tài nguyên với tên động dựa trên `${var.env_name}`:

```bash
cat << 'EOF' > modules/vpc/main.tf
# 1. Khởi tạo VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

# 2. Khởi tạo Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_name}-public-subnet"
  }
}

# 3. Khởi tạo Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.env_name}-igw"
  }
}

# 4. Khởi tạo Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.env_name}-public-rt"
  }
}

# 5. Liên kết Route Table với Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
EOF
```{{exec}}

---

### 2.4 — Xuất giá trị đầu ra của Child Module (`modules/vpc/outputs.tf`)

Module cần xuất ID của VPC và Subnet để Root Module và các module khác (như compute) có thể sử dụng:

```bash
cat << 'EOF' > modules/vpc/outputs.tf
output "vpc_id" {
  description = "ID của VPC vừa khởi tạo"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID của Public Subnet vừa khởi tạo"
  value       = aws_subnet.public.id
}
EOF
```{{exec}}

---

### 2.5 — Chuẩn hóa định dạng code module

Thực thi chuẩn hóa toàn bộ file trong module theo chuẩn cộng đồng:

```bash
terraform fmt -recursive
```{{exec}}

---

## 3. Bài Tập Thử Thách

Để các module khác có thể kiểm tra dải mạng của VPC khi cần:

1. Mở file `modules/vpc/outputs.tf` và bổ sung thêm một output:
   * **Tên output:** `vpc_cidr_block`
   * **Mô tả:** `"CIDR block của VPC"`
   * **Giá trị (value):** `aws_vpc.this.cidr_block`
2. Chạy lệnh sau để đảm bảo không có lỗi định dạng:
   ```bash
   terraform fmt -check modules/vpc
   ```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
