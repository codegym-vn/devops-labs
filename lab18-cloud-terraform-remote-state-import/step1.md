# Bước 1: Chuyển Đổi Sang Remote Backend (AWS S3 & DynamoDB State Locking)

Trong bước đầu tiên, bạn sẽ thiết lập hạ tầng lưu trữ trạng thái tập trung trên AWS: tạo **S3 Bucket** lưu trữ State, bảng **DynamoDB** quản lý khóa trạng thái (**State Locking**), và thực hiện di chuyển (**State Migration**) từ Local State lên Cloud.

---

## 1. Lý Thuyết: Cơ Chế Remote Backend Chuẩn Enterprise

### 1.1 — Bộ Đôi Hoàn Hảo: S3 + DynamoDB
* **AWS S3 (Lưu trữ):** Đóng vai trò là kho lưu trữ bền vững cho file `terraform.tfstate`. Hỗ trợ mã hóa (Server-side Encryption) và tính năng Versioning (lưu lịch sử từng phiên bản state, cho phép khôi phục nếu lỡ tay làm hỏng state).
* **AWS DynamoDB (Khóa trạng thái - State Locking):** Bảng DynamoDB này bắt buộc phải có một khóa chính (Partition Key) tên là **`LockID`** kiểu Chuỗi (`String`).
  * Khi bất kỳ ai chạy `terraform plan` hoặc `apply`, Terraform sẽ tạo một bản ghi vào bảng này.
  * Nếu người khác cùng gõ lệnh lúc đó, Terraform sẽ từ chối thực thi và báo lỗi khóa bận, ngăn chặn hoàn toàn nguy cơ Race Condition!

### 1.2 — Quy Trình Di Chuyển (Migration) An Toàn
Khi bạn thêm block `backend "s3"` vào dự án đang dùng Local State:
* Chạy `terraform init -migrate-state`
* Terraform sẽ tự động đọc toàn bộ tài nguyên trong file `terraform.tfstate` cục bộ, tải lên S3, và sao lưu file cục bộ cũ thành `terraform.tfstate.backup`.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục làm việc chính:

```bash
mkdir -p /root/terraform-remote-lab && cd /root/terraform-remote-lab
```{{exec}}

### 2.1 — Khởi tạo S3 Bucket & DynamoDB Table trên LocalStack

Sử dụng AWS CLI để tạo kho lưu trữ tập trung trước khi cấu hình Terraform:

```bash
# 1. Tạo S3 Bucket lưu trữ state
aws s3api create-bucket \
  --bucket devops-tfstate-bucket \
  --region us-east-1

echo "✅ Đã tạo S3 Bucket: devops-tfstate-bucket"

# 2. Tạo DynamoDB Table lưu State Lock (Bắt buộc khóa chính LockID)
aws dynamodb create-table \
  --table-name devops-tfstate-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "✅ Đã tạo DynamoDB Table: devops-tfstate-locks"
```{{exec}}

---

### 2.2 — Khởi tạo dự án ban đầu với Local State

Tạo `versions.tf`:

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

Tạo `provider.tf`:

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
    ec2      = "http://localhost:4566"
    sts      = "http://localhost:4566"
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
  }
}
EOF
```{{exec}}

Tạo `main.tf` định nghĩa một mạng VPC nền tảng:

```bash
cat << 'EOF' > main.tf
resource "aws_vpc" "core" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "core-vpc"
  }
}
EOF
```{{exec}}

Khởi tạo và apply bằng Local State thông thường:

```bash
terraform init
terraform apply -auto-approve
```{{exec}}

Quan sát: File `terraform.tfstate` đang nằm trực tiếp ở thư mục làm việc cục bộ của bạn (`ls -la terraform.tfstate`).

---

### 2.3 — Cấu hình Remote Backend (`backend.tf`) & Di chuyển State lên S3

Tạo file `backend.tf`:

```bash
cat << 'EOF' > backend.tf
terraform {
  backend "s3" {
    bucket                      = "devops-tfstate-bucket"
    key                         = "network/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://localhost:4566"
    dynamodb_table              = "devops-tfstate-locks"
    dynamodb_endpoint           = "http://localhost:4566"
    encrypt                     = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
EOF
```{{exec}}

Thực hiện lệnh di chuyển trạng thái với cờ `-migrate-state -force-copy`:

```bash
terraform init -migrate-state -force-copy
```{{exec}}

Quan sát đầu ra:
* `Do you want to copy existing state to the new backend?`
* `Successfully configured the backend "s3"! Terraform will automatically use this backend unless the configuration changes.`

---

### 2.4 — Kiểm chứng trạng thái trên S3

Kiểm tra xem file `terraform.tfstate` đã được lưu trữ thành công trên S3 Bucket hay chưa:

```bash
aws s3 ls s3://devops-tfstate-bucket/network/
```{{exec}}

Bạn sẽ thấy file `terraform.tfstate` xuất hiện trên S3! Kể từ lúc này, mọi thao tác `plan`, `apply`, `destroy` sẽ tự động đồng bộ trực tiếp với S3 và DynamoDB.

---

## 3. Bài Tập Thử Thách: Bật Tính Năng Versioning Cho S3 State

Trong môi trường Production, S3 Bucket lưu State **bắt buộc phải bật Versioning** để đề phòng rủi ro bị ghi đè hoặc hỏng file:

1. Dùng lệnh AWS CLI sau để kích hoạt Versioning cho Bucket `devops-tfstate-bucket`:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket devops-tfstate-bucket \
     --versioning-configuration Status=Enabled
   ```{{exec}}
2. Kiểm tra lại trạng thái versioning:
   ```bash
   aws s3api get-bucket-versioning --bucket devops-tfstate-bucket
   ```{{exec}}
   *(Kết quả hiển thị `"Status": "Enabled"`).*

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
