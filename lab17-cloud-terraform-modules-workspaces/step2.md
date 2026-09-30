# Bước 2: Đóng Gói Module Compute & Kết Nối Liên Module

Trong bước này, bạn sẽ đóng gói **Child Module Compute** (quản lý Security Group và máy ảo EC2), sau đó kết nối liên module tại **Root Module** bằng cách truyền giá trị đầu ra (Output) của module mạng vào làm đầu vào (Input) của module compute.

---

## 1. Lý Thuyết: Kết Nối Liên Module (Inter-Module Communication)

Trong kiến trúc chuẩn hóa:
* **Tính độc lập (Decoupling):** Module Compute không cần biết chi tiết mạng VPC được chia subnet ra sao hay có bao nhiêu route table. Nó chỉ cần 2 thông tin tối thiểu: `vpc_id` (để tạo Security Group) và `subnet_id` (để gắn card mạng cho máy ảo).
* **Kết nối qua Root Module:** Root Module đóng vai trò là "nhạc trưởng":
  1. Gọi `module "vpc"` → nhận về `module.vpc.vpc_id` và `module.vpc.public_subnet_id`.
  2. Truyền các giá trị đó trực tiếp vào các tham số đầu vào của `module "compute"`.
* **Đăng ký module (`terraform init`):** Mỗi khi bạn thêm một block `module` mới trỏ tới thư mục cục bộ hoặc từ xa, bạn **BẮT BUỘC** phải chạy lại `terraform init` để Terraform quét cây module và ghi vào `.terraform/modules/modules.json`.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-workspaces-lab`.

### 2.1 — Khởi tạo Child Module Compute (`modules/compute`)

Tạo thư mục con:

```bash
mkdir -p modules/compute
```{{exec}}

Tạo file biến đầu vào `modules/compute/variables.tf`:

```bash
cat << 'EOF' > modules/compute/variables.tf
variable "env_name" {
  description = "Tên môi trường (dev/prod) để gán nhãn nhận diện"
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC gắn với Security Group"
  type        = string
}

variable "subnet_id" {
  description = "ID của Subnet nơi đặt máy ảo EC2"
  type        = string
}

variable "instance_type" {
  description = "Loại phần cứng của máy ảo EC2"
  type        = string
  default     = "t2.micro"
}
EOF
```{{exec}}

Tạo logic tài nguyên tại `modules/compute/main.tf`:

```bash
cat << 'EOF' > modules/compute/main.tf
# 1. Tường lửa Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.env_name}-web-sg"
  description = "Security Group cho Web Server moi truong ${var.env_name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_name}-web-sg"
  }
}

# 2. Máy ảo EC2
resource "aws_instance" "web" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.env_name}-web-server"
  }
}
EOF
```{{exec}}

Tạo file xuất giá trị đầu ra `modules/compute/outputs.tf`:

```bash
cat << 'EOF' > modules/compute/outputs.tf
output "instance_id" {
  description = "ID của máy ảo EC2"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP của máy ảo EC2"
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "ID của Security Group"
  value       = aws_security_group.web_sg.id
}
EOF
```{{exec}}

---

### 2.2 — Cấu hình biến toàn cục và kết nối tại Root Module

Tại thư mục gốc `/root/terraform-workspaces-lab`:

Tạo `variables.tf`:

```bash
cat << 'EOF' > variables.tf
variable "env_name" {
  description = "Tên môi trường triển khai"
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

variable "instance_type" {
  description = "Loại máy ảo EC2"
  type        = string
  default     = "t2.micro"
}
EOF
```{{exec}}

Tạo file `main.tf` ở thư mục gốc để kết nối 2 Child Modules lại với nhau:

```bash
cat << 'EOF' > main.tf
# 1. Gọi Module Mạng
module "vpc" {
  source             = "./modules/vpc"
  env_name           = var.env_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

# 2. Gọi Module Compute (Nhận output từ module vpc)
module "compute" {
  source        = "./modules/compute"
  env_name      = var.env_name
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  instance_type = var.instance_type
}
EOF
```{{exec}}

Tạo `outputs.tf` ở thư mục gốc để trích xuất thông tin chung:

```bash
cat << 'EOF' > outputs.tf
output "vpc_id" {
  description = "ID của VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID của Public Subnet"
  value       = module.vpc.public_subnet_id
}

output "web_instance_id" {
  description = "ID của EC2 Web Server"
  value       = module.compute.instance_id
}

output "web_instance_public_ip" {
  description = "Public IP của EC2 Web Server"
  value       = module.compute.instance_public_ip
}
EOF
```{{exec}}

---

### 2.3 — Khởi tạo đăng ký Module & Kiểm tra tính hợp lệ

Chạy `terraform init` để Terraform đăng ký các Child Modules vào bộ nhớ quản lý:

```bash
terraform init
```{{exec}}

Quan sát thông báo:
* `Initializing modules...`: Terraform tìm thấy `- compute in modules/compute` và `- vpc in modules/vpc`.

Chạy kiểm tra cú pháp và liên kết:

```bash
terraform validate
```{{exec}}

Nếu thấy `Success! The configuration is valid.` thì hệ thống Module của bạn đã được kết nối hoàn hảo!

---

## 3. Bài Tập Thử Thách

Tăng cường an ninh mạng cho Web Server bằng cách hỗ trợ HTTPS:

1. Mở file `modules/compute/main.tf`, thêm một quy tắc `ingress` cho cổng `443` (HTTPS) vào resource `aws_security_group.web_sg`:
   * `from_port = 443`, `to_port = 443`, `protocol = "tcp"`, `cidr_blocks = ["0.0.0.0/0"]`.
2. Chạy `terraform fmt -recursive` và kiểm tra lại bằng:
   ```bash
   terraform validate
   ```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
