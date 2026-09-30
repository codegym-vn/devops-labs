# Bước 3: Import Tài Nguyên Thủ Công Bằng Lệnh 'terraform import'

Trong bước này, bạn sẽ đóng vai một kỹ sư tiếp quản hạ tầng có sẵn: đưa một nhóm bảo mật (**Security Group**) được tạo thủ công bằng tay (ClickOps) vào quản lý bằng mã nguồn Terraform bằng lệnh **`terraform import`** truyền thống.

---

## 1. Lý Thuyết: Bản Chất Của Lệnh `terraform import`

Khi bạn chạy lệnh:
```bash
terraform import <RESOURCE_ADDRESS> <CLOUD_PHYSICAL_ID>
```
* **Terraform làm gì?** Nó gọi API Cloud đọc thông số thực tế của `<CLOUD_PHYSICAL_ID>`, sau đó ghi toàn bộ thuộc tính đó vào file **State** (`terraform.tfstate`) dưới tên định danh `<RESOURCE_ADDRESS>`.
* **Terraform KHÔNG làm gì?** Lệnh này **KHÔNG hề tự động sinh ra mã nguồn HCL** vào file `.tf` cho bạn!
* **Quy trình chuẩn mực:**
  1. Viết một khối `resource` rỗng trong file `.tf`.
  2. Thực thi lệnh `terraform import`.
  3. Sử dụng `terraform state show` để đọc thông số state vừa nạp.
  4. Bổ sung các thuộc tính vào file `.tf` và chạy `terraform plan` cho đến khi đạt trạng thái:
     `No changes. Your infrastructure matches the configuration.`

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-remote-lab`.

### 2.1 — Giả lập tài nguyên tạo thủ công ngoài luồng bằng AWS CLI

Lấy ID của VPC hiện tại và tạo một Security Group thủ công kèm quy tắc mở cổng 80:

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=core-vpc" --query "Vpcs[0].VpcId" --output text)

LEGACY_SG_ID=$(aws ec2 create-security-group \
  --group-name "manual-legacy-sg" \
  --description "Security Group duoc tao thu cong ngoai luong" \
  --vpc-id $VPC_ID \
  --query "GroupId" \
  --output text)

# Mở Inbound port 80 cho Security Group này
aws ec2 authorize-security-group-ingress \
  --group-id $LEGACY_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

echo "✅ Đã tạo Security Group thủ công: $LEGACY_SG_ID (VPC: $VPC_ID)"
echo "LEGACY_SG_ID=$LEGACY_SG_ID" > /tmp/import-env.sh
```{{exec}}

---

### 2.2 — Khai báo khung tài nguyên rỗng & Thực thi Import

Tạo file `imported.tf` chứa khung định danh:

```bash
cat << 'EOF' > imported.tf
resource "aws_security_group" "manual_sg" {
  # Khung rỗng chuẩn bị nhận dữ liệu từ lệnh import
}
EOF
```{{exec}}

Nạp tài nguyên vào State bằng lệnh `terraform import`:

```bash
source /tmp/import-env.sh
terraform import aws_security_group.manual_sg $LEGACY_SG_ID
```{{exec}}

Quan sát đầu ra:
* `aws_security_group.manual_sg: Importing from ID "sg-xxxxxxxx"...`
* `Import successful!`
* `The resources that were imported are shown above. These resources are now in your Terraform state and will henceforth be managed by Terraform.`

---

### 2.3 — Mổ xẻ State và hoàn thiện code HCL

1. **Xem thuộc tính chi tiết trong State:**
   ```bash
   terraform state show aws_security_group.manual_sg
   ```{{exec}}

2. **Cập nhật code HCL trong `imported.tf` cho khớp với thực tế:**
   ```bash
   cat << 'EOF' > imported.tf
   resource "aws_security_group" "manual_sg" {
     name        = "manual-legacy-sg"
     description = "Security Group duoc tao thu cong ngoai luong"
     vpc_id      = aws_vpc.main.id

     ingress {
       description = "HTTP Inbound"
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }

     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }
   }
   EOF
   ```{{exec}}

3. **Chạy `terraform plan` để kiểm tra độ lệch:**
   ```bash
   terraform plan
   ```{{exec}}
   *Nếu kết quả báo `No changes` hoặc chỉ cập nhật nhỏ về thẻ mô tả, nghĩa là code HCL và hạ tầng thực tế đã đồng bộ hoàn toàn!*

---

## 3. Bài Tập Thử Thách

Sau khi đã đưa thành công Security Group vào quản lý bằng Terraform, hãy bổ sung thẻ Tag quản trị theo chuẩn doanh nghiệp:

1. Mở file `imported.tf`, thêm block `tags` vào `aws_security_group.manual_sg`:
   ```hcl
   tags = {
     Environment = "migrated"
     ManagedBy   = "terraform"
   }
   ```
2. Chạy `terraform apply -auto-approve` để áp dụng thẻ Tag này lên Cloud.
3. Kiểm tra lại bằng AWS CLI:
   ```bash
   source /tmp/import-env.sh
   aws ec2 describe-security-groups --group-ids $LEGACY_SG_ID --output table
   ```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
