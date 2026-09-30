# Bước 4: Khai Báo 'import {}' Khối Hiện Đại & Xác Minh Tính Đồng Bộ Toàn Diện

Trong bước cuối cùng này, bạn sẽ sử dụng tính năng **Declarative Import Block (`import {}`)** ra mắt từ Terraform 1.5+ để tự động sinh mã nguồn HCL, xác minh tính đồng bộ tuyệt đối giữa Code <───> Remote State S3 <───> Cloud, và thực hiện dọn dẹp hạ tầng an toàn.

---

## 1. Lý Thuyết: Cuộc Cách Mạng Khối Khai Báo `import {}`

Ở Bước 3, bạn đã thấy hạn chế lớn của lệnh `terraform import` cũ: kỹ sư phải tự tay mò mẫm gõ code HCL vào file `.tf`, rất dễ sai sót hoặc lệch thuộc tính so với thực tế.

Từ Terraform 1.5+, HashiCorp bổ sung khối khai báo:

```hcl
import {
  to = <TÊN_RESOURCE_TRONG_CODE>
  id = "<CLOUD_PHYSICAL_ID>"
}
```

Kết hợp với cờ **`-generate-config-out`**:
```bash
terraform plan -generate-config-out=generated_resources.tf
```
* **Điều kỳ diệu xảy ra:** Terraform sẽ tự động đọc tài nguyên trên Cloud và **tự viết mã nguồn HCL hoàn chỉnh** vào file `generated_resources.tf`!
* Quy trình này mang tính khai báo (Declarative), cho phép bạn tạo Pull Request để cả team cùng review trước khi tài nguyên thực sự được nạp vào State.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-remote-lab`.

### 2.1 — Tạo một Subnet thủ công bằng AWS CLI

Khởi tạo một Subnet mới hoàn toàn nằm ngoài sự kiểm soát của Terraform:

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=core-vpc" --query "Vpcs[0].VpcId" --output text)

MANUAL_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.88.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=legacy-unmanaged-subnet}]' \
  --query "Subnet.SubnetId" \
  --output text)

echo "✅ Đã tạo Subnet thủ công: $MANUAL_SUBNET_ID (CIDR: 10.0.88.0/24)"
echo "MANUAL_SUBNET_ID=$MANUAL_SUBNET_ID" > /tmp/manual-subnet.sh
```{{exec}}

---

### 2.2 — Khai báo khối `import {}` & Tự động sinh mã nguồn HCL

Tạo file `declarative_import.tf`:

```bash
source /tmp/manual-subnet.sh

cat << EOF > declarative_import.tf
import {
  to = aws_subnet.legacy_subnet
  id = "$MANUAL_SUBNET_ID"
}
EOF
```{{exec}}

Chạy lệnh `terraform plan` kèm cờ `-generate-config-out=generated_subnet.tf`:

```bash
terraform plan -generate-config-out=generated_subnet.tf
```{{exec}}

Quan sát đầu ra:
* `aws_subnet.legacy_subnet will be imported...`
* `Generating configuration for aws_subnet.legacy_subnet...`
* `Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.`

Nhìn vào cây thư mục bên trái của Theia IDE, bạn sẽ thấy file **`generated_subnet.tf`** xuất hiện! Xem nội dung:

```bash
cat generated_subnet.tf
```{{exec}}

Toàn bộ code HCL cho `aws_subnet.legacy_subnet` với dải CIDR `10.0.88.0/24` đã được Terraform tự động sinh ra chuẩn xác 100%!

---

### 2.3 — Áp dụng Import lên Remote State S3

Chạy lệnh apply để xác nhận nạp tài nguyên vào State lưu trữ trên S3:

```bash
terraform apply -auto-approve
```{{exec}}

Kiểm tra danh sách tài nguyên trong Remote State:

```bash
terraform state list
```{{exec}}

Bạn sẽ thấy cả `aws_vpc.main`, `aws_security_group.manual_sg` và `aws_subnet.legacy_subnet` đang cùng được quản lý tập trung và an toàn trên Remote Backend S3!

---

### 2.4 — Xác minh tính đồng bộ & Dọn dẹp toàn diện (Destroy)

Chạy `terraform plan` để kiểm tra độ đồng bộ:

```bash
terraform plan
```{{exec}}

*Thông báo:* `No changes. Your infrastructure matches the configuration.`  
Ba thành phần: **Mã nguồn HCL**, **Remote State trên S3** và **Hạ tầng thực tế trên LocalStack** đã đồng bộ tuyệt đối 100%!

Thực hiện dọn dẹp sạch sẽ toàn bộ tài nguyên:

```bash
terraform destroy -auto-approve
```{{exec}}

Quan sát: Terraform dọn dẹp sạch cả những tài nguyên ban đầu được tạo thủ công ngoài luồng, chứng minh toàn bộ hạ tầng đã hoàn toàn nằm trong quyền kiểm soát của IaC!

Kiểm tra lại bằng AWS CLI:

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=core-vpc" --query "Vpcs" --output text
```{{exec}}

*Kết quả rỗng:* Toàn bộ hạ tầng đã được xóa bỏ an toàn!

---

## 3. Bài Tập Thử Thách

1. Kiểm tra S3 Bucket bằng lệnh AWS CLI:
   ```bash
   aws s3 ls s3://devops-tfstate-bucket/network/
   ```{{exec}}
2. Tải file `terraform.tfstate` từ S3 về xem để xác nhận sau khi destroy, mảng `resources` bên trong đã trở về rỗng:
   ```bash
   aws s3 cp s3://devops-tfstate-bucket/network/terraform.tfstate /tmp/s3-state.json
   jq '.resources | length' /tmp/s3-state.json
   ```{{exec}}
   *(Kết quả hiển thị `0`).*

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
