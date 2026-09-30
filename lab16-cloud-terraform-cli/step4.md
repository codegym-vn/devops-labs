# Bước 4: Cập Nhật Hạ Tầng (In-Place Drift Update) & Hủy Diệt (Destroy)

Trong bước cuối cùng này, bạn sẽ thực hiện các thao tác vận hành ngày thứ hai (**Day-2 Operations**): cập nhật cấu hình hạ tầng tại chỗ (**In-place Update**), dọn dẹp toàn bộ tài nguyên bằng lệnh **`terraform destroy`**, và kiểm chứng tính tái lập bất biến (**Idempotency**).

---

## 1. Lý Thuyết: Cập Nhật Tại Chỗ vs Thay Thế & Cơ Chế Hủy Diệt

### 1.1 — Phân Loại Thay Đổi Trong Terraform
Khi mã nguồn `.tf` thay đổi, Terraform phân tích thuộc tính và đưa ra 1 trong 2 quyết định:
1. **Cập nhật tại chỗ (`~ update in-place`):** Thay đổi các thuộc tính linh hoạt (mở thêm port tường lửa, thêm thẻ Tag...). Thao tác này an toàn, không gây downtime.
2. **Hủy và tạo lại mới (`-/+ destroy and then create replacement`):** Xảy ra khi bạn thay đổi các thuộc tính bất biến của Cloud (ví dụ: đổi AMI máy ảo, chuyển Subnet, hoặc đổi CIDR của VPC). Terraform sẽ buộc phải xóa máy ảo cũ và tạo máy ảo mới.

### 1.2 — Sức Mạnh Của `terraform destroy`
Ở Lab 12, khi dọn dẹp hạ tầng bằng AWS CLI, nếu bạn lỡ tay xóa VPC trước khi xóa máy ảo hoặc gỡ Internet Gateway, AWS sẽ ngay lập tức chặn lại bằng lỗi:
`DependencyViolation: The vpc has dependencies and cannot be deleted.`

Với Terraform, lệnh `terraform destroy` sẽ tự động duyệt **ngược chiều** đồ thị phụ thuộc (DAG):
$$\text{EC2} \longrightarrow \text{Security Group} \longrightarrow \text{Route Association} \longrightarrow \text{Subnet} \longrightarrow \text{IGW} \longrightarrow \text{VPC}$$
Toàn bộ tài nguyên sẽ được dọn dẹp sạch sẽ, không để lại bất kỳ tài nguyên mồ côi (Orphan Resources) nào gây lãng phí chi phí.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-lab`.

### 2.1 — Cập nhật cấu hình: Mở thêm cổng HTTPS (Port 443)

Mở file `compute.tf` và thêm một block `ingress` cho cổng 443 vào bên trong resource `aws_security_group.web_sg`:

```bash
cat << 'EOF' > compute.tf
# 1. Tường lửa Security Group cho Web Server (Đã bổ sung port 443)
resource "aws_security_group" "web_sg" {
  name        = "tf-web-sg"
  description = "Allow inbound HTTP, HTTPS and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
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

### 2.2 — Quan sát kế hoạch cập nhật In-place (`terraform plan`)

Chạy lệnh kiểm tra thay đổi:

```bash
terraform plan
```{{exec}}

Quan sát đầu ra:
* Ký hiệu `~ update in-place` xuất hiện bên cạnh `aws_security_group.web_sg`.
* Dòng kết luận: `Plan: 0 to add, 1 to change, 0 to destroy.`
* Terraform nhận biết chính xác: Máy ảo EC2 **không bị ảnh hưởng**, chỉ có Security Group được cập nhật rule mới!

Áp dụng thay đổi ngay:

```bash
terraform apply -auto-approve
```{{exec}}

---

### 2.3 — Dọn dẹp toàn bộ hạ tầng (`terraform destroy`)

Khi kết thúc chu kỳ phát triển hoặc tắt môi trường thử nghiệm để tiết kiệm chi phí, thực hiện dọn dẹp bằng 1 lệnh duy nhất:

```bash
terraform destroy -auto-approve
```{{exec}}

Quan sát quá trình:
1. Terraform liệt kê 8 tài nguyên sẽ bị hủy: `Plan: 0 to add, 0 to change, 8 to destroy.`
2. Thứ tự hủy diễn ra chuẩn xác: EC2 $\rightarrow$ SG $\rightarrow$ Subnet $\rightarrow$ IGW $\rightarrow$ VPC.
3. Thông báo: `Destroy complete! Resources: 8 destroyed.`

Kiểm tra lại bằng AWS CLI:

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tf-vpc" --query "Vpcs" --output text
```{{exec}}

Kết quả rỗng: Toàn bộ hạ tầng đã được xóa bỏ hoàn toàn sạch sẽ!

---

## 3. Bài Tập Thử Thách: Sức Mạnh Tái Lập Bất Biến (Idempotency)

Tình huống thực tế: Team sản phẩm yêu cầu dựng lại một môi trường Dev giống hệt môi trường vừa hủy để phục vụ kiểm thử.

1. Bạn chỉ cần chạy đúng **1 lệnh duy nhất**:
   ```bash
   terraform apply -auto-approve
   ```{{exec}}
2. Kiểm tra lại danh sách tài nguyên vừa được tái sinh:
   ```bash
   terraform state list
   ```{{exec}}
3. Xác nhận rằng Security Group `tf-web-sg` vừa tạo mới vẫn giữ nguyên đầy đủ cả 3 cổng: **80, 443 và 22**.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
