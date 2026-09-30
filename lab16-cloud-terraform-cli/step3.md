# Bước 3: Lập Kế Hoạch Triển Khai EC2, Security Group & Khám Phá State File

Trong bước này, bạn sẽ bổ sung tài nguyên điện toán (**EC2**) và tường lửa (**Security Group**), tạo **Execution Plan**, thực thi **Apply** hạ tầng lên Cloud và mổ xẻ "trái tim" của Terraform: file trạng thái **`terraform.tfstate`**.

---

## 1. Lý Thuyết: Plan, Apply & "Trái Tim" State File

### 1.1 — Tại Sao Phải Chạy `terraform plan -out`?
* Lệnh `terraform plan` so sánh code của bạn với dữ liệu thực tế trên Cloud và dự báo chính xác các hành động sẽ diễn ra:
  * `+ create`: Tài nguyên mới sẽ được tạo.
  * `~ update in-place`: Thuộc tính được cập nhật mà không xóa tài nguyên.
  * `- destroy`: Tài nguyên sẽ bị xóa bỏ.
  * `-/+ replace`: Tài nguyên cũ bị xóa và tạo lại mới (ví dụ khi đổi Subnet hoặc AMI).
* **Best Practice Production:** Sử dụng tham số `-out=tfplan` để lưu lại kế hoạch thành tệp nhị phân. Khi chạy `terraform apply tfplan`, Terraform cam kết thực thi **chính xác** những gì bạn vừa review, loại bỏ hoàn toàn nguy cơ có ai đó thay đổi Cloud ngầm giữa lúc lập plan và lúc apply.

### 1.2 — Bí Mật Của `terraform.tfstate`
File `terraform.tfstate` là bộ não ánh xạ (Mapping) giữa:

```text
Code HCL (aws_instance.web) <───> Physical Cloud ID (i-0a1b2c3d4e5f)
```

* Nếu không có state file, Terraform sẽ không biết tài nguyên nào đã tồn tại và sẽ cố gắng tạo mới, gây xung đột.
* **Quy tắc bảo mật:** State file có thể chứa dữ liệu nhạy cảm dạng plaintext (mật khẩu DB, private keys). Tuyệt đối **KHÔNG** commit file này lên public Git! Trong môi trường thực tế, state được lưu tại Remote Backend (như AWS S3 + DynamoDB State Locking).

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-lab`.

### 2.1 — Khai báo Security Group & EC2 Instance (`compute.tf`)

Tạo file `compute.tf` để cấu hình tường lửa và máy chủ:

```bash
cat << 'EOF' > compute.tf
# 1. Tường lửa Security Group cho Web Server
resource "aws_security_group" "web_sg" {
  name        = "tf-web-sg"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

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
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-web-sg"
  }
}

# 2. Khởi tạo máy ảo EC2 Web Server
resource "aws_instance" "web" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "tf-web-server"
  }
}
EOF
```{{exec}}

---

### 2.2 — Bổ sung Output cho EC2 vào `outputs.tf`

Mở rộng `outputs.tf` để xuất ID và địa chỉ IP của máy chủ:

```bash
cat << 'EOF' >> outputs.tf

output "web_instance_id" {
  description = "ID của EC2 Web Server"
  value       = aws_instance.web.id
}

output "web_instance_public_ip" {
  description = "Public IP của EC2 Web Server"
  value       = aws_instance.web.public_ip
}
EOF
```{{exec}}

---

### 2.3 — Lập kế hoạch thực thi (`terraform plan`)

Tạo file kế hoạch thực thi nhị phân `tfplan`:

```bash
terraform plan -out=tfplan
```{{exec}}

Hãy kéo lên và quan sát dòng tổng kết cuối cùng:
`Plan: 8 to add, 0 to change, 0 to destroy.`
Terraform đã tự động phân tích đồ thị phụ thuộc và lập danh sách 8 tài nguyên cần tạo mới!

---

### 2.4 — Áp dụng kế hoạch lên Cloud (`terraform apply`)

Áp dụng chính xác file kế hoạch vừa sinh ra:

```bash
terraform apply tfplan
```{{exec}}

Chỉ sau vài giây, bạn sẽ thấy kết quả:
* `Apply complete! Resources: 8 added, 0 changed, 0 destroyed.`
* Danh sách Outputs hiện rõ ID của VPC, Subnet và EC2 Web Server.

---

### 2.5 — Khám phá State File & Đối chứng AWS CLI

1. **Xem danh sách tài nguyên trong State:**
   ```bash
   terraform state list
   ```{{exec}}

2. **Xem chi tiết thông số của máy ảo từ State:**
   ```bash
   terraform state show aws_instance.web
   ```{{exec}}

3. **Mở xem file `terraform.tfstate`:**
   Nhìn vào cây thư mục bên trái của Theia IDE, bạn sẽ thấy file `terraform.tfstate` xuất hiện. Bạn có thể click vào xem hoặc dùng lệnh:
   ```bash
   head -n 25 terraform.tfstate
   ```{{exec}}

4. **Đối chứng độc lập bằng AWS CLI:**
   Kiểm tra xem máy ảo có thực sự tồn tại trên LocalStack hay không:
   ```bash
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=tf-web-server" \
     --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress]" \
     --output table
   ```{{exec}}

Máy ảo đang ở trạng thái `running` với Public IP trùng khớp hoàn toàn với những gì Terraform báo cáo!

---

## 3. Bài Tập Thử Thách

1. Chạy lệnh `terraform output` để xem lại toàn bộ các giá trị đầu ra của hạ tầng.
2. Dùng lệnh `terraform state show` để xem cấu hình chi tiết của Security Group `aws_security_group.web_sg`.
3. Kiểm tra xem Security Group đó có đúng là đang mở port 80 và port 22 hay không.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
