# Bước 2: Khai Báo Mạng VPC, Subnet & Quản Lý Biến Số (Variables & Outputs)

Trong bước này, bạn sẽ lập trình toàn bộ hạ tầng mạng (VPC, Subnet, Internet Gateway, Route Table) bằng ngôn ngữ **HCL**, áp dụng nguyên lý tách biệt cấu hình bằng **Variables** và xuất dữ liệu hạ tầng qua **Outputs**.

---

## 1. Lý Thuyết: Cấu Trúc Khai Báo Tài Nguyên Trong Terraform

### 1.1 — Cú Pháp Resource Block
Một khối tài nguyên trong HCL luôn tuân theo mẫu:

```hcl
resource "<RESOURCE_TYPE>" "<LOCAL_NAME>" {
  # Các thuộc tính (arguments)
}
```
* `<RESOURCE_TYPE>`: Loại tài nguyên do Provider cung cấp (ví dụ `aws_vpc`, `aws_subnet`).
* `<LOCAL_NAME>`: Tên định danh cục bộ trong code Terraform (ví dụ `main`, `public`).
* **Tham chiếu ngầm định (Implicit Dependency):** Khi bạn viết `vpc_id = aws_vpc.main.id`, Terraform tự động hiểu rằng: *Phải tạo VPC trước, lấy ID được sinh ra rồi mới truyền vào để tạo Subnet*. Bạn không cần phải viết logic chờ đợi hay điều hướng luồng!

### 1.2 — Nguyên Lý DRY: Variables & Outputs
* **`variables.tf` (Đầu vào):** Định nghĩa các biến tham số hóa (dải IP, môi trường, số lượng máy chủ...) giúp code có thể tái sử dụng cho nhiều môi trường (Dev, Staging, Prod).
* **`outputs.tf` (Đầu ra):** Định nghĩa các giá trị cần hiển thị sau khi triển khai xong (VPC ID, Public IP máy ảo, DNS name...), cho phép các module khác hoặc script CI/CD sử dụng tiếp.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-lab`.

### 2.1 — Khai báo các biến đầu vào (`variables.tf`)

Tạo file `variables.tf` để tham số hóa dải IP của mạng:

```bash
cat << 'EOF' > variables.tf
variable "vpc_cidr" {
  description = "Dải CIDR block cho Virtual Private Cloud"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Dải CIDR block cho Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "environment" {
  description = "Môi trường triển khai (dev/staging/prod)"
  type        = string
  default     = "dev"
}
EOF
```{{exec}}

---

### 2.2 — Khai báo kiến trúc mạng ảo (`vpc.tf`)

Tạo file `vpc.tf` chứa toàn bộ thành phần mạng: VPC, Public Subnet, Internet Gateway và Route Table:

```bash
cat << 'EOF' > vpc.tf
# 1. Khởi tạo VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf-vpc"
  }
}

# 2. Khởi tạo Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-subnet"
  }
}

# 3. Khởi tạo Internet Gateway (IGW)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-igw"
  }
}

# 4. Khởi tạo Route Table trỏ ra Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "tf-public-rt"
  }
}

# 5. Liên kết Route Table với Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
EOF
```{{exec}}

---

### 2.3 — Khai báo các đầu ra cần trích xuất (`outputs.tf`)

Tạo file `outputs.tf`:

```bash
cat << 'EOF' > outputs.tf
output "vpc_id" {
  description = "ID định danh của VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID của Public Subnet"
  value       = aws_subnet.public.id
}
EOF
```{{exec}}

---

### 2.4 — Chuẩn hóa định dạng (`terraform fmt`) & Kiểm tra cú pháp (`terraform validate`)

Trước khi lập kế hoạch triển khai, hai lệnh sau là tiêu chuẩn bắt buộc trong quy trình CI/CD:

1. **`terraform fmt`:** Tự động căn chỉnh lề, dấu bằng, khoảng trắng theo chuẩn HCL:
   ```bash
   terraform fmt
   ```{{exec}}

2. **`terraform validate`:** Kiểm tra tính hợp lệ về kiểu dữ liệu, các thuộc tính bắt buộc và các tham chiếu giữa các resource:
   ```bash
   terraform validate
   ```{{exec}}

Nếu thấy thông báo: `Success! The configuration is valid.` thì code của bạn đã hoàn toàn sẵn sàng!

---

## 3. Bài Tập Thử Thách

Hệ thống cần bổ sung một mạng con biệt lập (Private Subnet) dành cho cụm cơ sở dữ liệu:

1. Trong file `variables.tf`, khai báo thêm một biến:
   * **Tên biến:** `private_subnet_cidr`
   * **Kiểu:** `string`
   * **Giá trị mặc định (default):** `"10.0.2.0/24"`
2. Trong file `vpc.tf`, khai báo thêm resource:
   * **Type:** `aws_subnet`
   * **Tên cục bộ:** `"private"`
   * **Thuộc tính:** `vpc_id = aws_vpc.main.id`, `cidr_block = var.private_subnet_cidr`, gắn thẻ `Name = "tf-private-subnet"`.
3. Trong file `outputs.tf`, thêm một output:
   * **Tên output:** `private_subnet_id`
   * **Giá trị:** `aws_subnet.private.id`
4. Chạy `terraform fmt` và `terraform validate` để đảm bảo không có lỗi cú pháp.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
