# Bước 1: Khởi Tạo Project & Cấu Hình Provider AWS Với LocalStack

Trong bước đầu tiên này, bạn sẽ thiết lập nền tảng cho một dự án Terraform chuẩn Production: định nghĩa yêu cầu phiên bản, cấu hình **AWS Provider** trỏ tới **LocalStack**, và thực thi lệnh khởi tạo `terraform init`.

---

## 1. Lý Thuyết: Terraform Provider & Cơ Chế Khởi Tạo

### 1.1 — Provider Là Gì?
Terraform là một **Core Engine** độc lập; bản thân nó không trực tiếp biết cách tạo một VPC hay một máy ảo trên AWS. Thay vào đó, Terraform sử dụng kiến trúc **Plugin** gọi là **Providers**.
* Provider đóng vai trò như một "thông dịch viên": dịch mã nguồn HCL thành các lệnh gọi API RESTful tương ứng của nhà cung cấp điện toán đám mây (AWS, GCP, Azure, Cloudflare...).
* Nhà cung cấp chính thức của AWS là `hashicorp/aws` được lưu trữ tại Terraform Registry công khai.

### 1.2 — Tệp Khóa Phụ Thuộc (`.terraform.lock.hcl`)
Khi bạn chạy `terraform init`, Terraform sẽ tải binary của Provider và tự động tạo ra file `.terraform.lock.hcl`:
* File này lưu trữ chính xác phiên bản Provider đã tải và các chuỗi băm bảo mật (SHA-256 Checksums).
* **Quy tắc vàng DevOps:** File `.terraform.lock.hcl` **BẮT BUỘC** phải được commit vào Git repository để đảm bảo mọi thành viên trong team và hệ thống CI/CD luôn sử dụng phiên bản Provider đồng nhất 100%, tránh rủi ro vỡ hạ tầng do Provider tự động cập nhật phiên bản mới.

---

## 2. Thực Hành

Đảm bảo bạn đang ở trong thư mục làm việc chính:

```bash
mkdir -p /root/terraform-lab && cd /root/terraform-lab
```{{exec}}

### 2.1 — Khởi tạo tệp khai báo phiên bản (`versions.tf`)

Tạo file `versions.tf` để ràng buộc phiên bản tối thiểu của Terraform Core và Provider AWS:

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

> [!NOTE]
> Cú pháp `~> 5.0` (Pessimistic Constraint Operator) cho phép nhận các bản cập nhật phụ an toàn (như `5.1`, `5.28`...) nhưng không tự động nâng lên bản lớn `6.0` (Major Version) có thể chứa Breaking Changes.

---

### 2.2 — Cấu hình AWS Provider kết nối LocalStack (`provider.tf`)

Trong môi trường thực tế, AWS Provider sẽ đọc Access Key / Secret Key từ IAM Role hoặc cấu hình máy chủ. Trong bài lab này, chúng ta trỏ các API Endpoint về **LocalStack** (`http://localhost:4566`):

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

  default_tags {
    tags = {
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}
EOF
```{{exec}}

> [!TIP]
> Tính năng `default_tags` của AWS Provider là một Best Practice cực kỳ quan trọng trong FinOps & Governance: mọi tài nguyên (VPC, Subnet, EC2...) được tạo ra bởi Provider này sẽ tự động được gán các thẻ tag trên mà không cần bạn phải lặp lại code ở từng block tài nguyên!

---

### 2.3 — Thực thi lệnh `terraform init`

Lệnh này sẽ quét toàn bộ code `.tf` trong thư mục hiện tại, tìm các Provider được yêu cầu, tải plugin và chuẩn bị môi trường chạy:

```bash
terraform init
```{{exec}}

Quan sát kết quả đầu ra:
1. `Initializing provider plugins...`: Terraform tìm thấy `hashicorp/aws`.
2. Do hệ thống lab đã cấu hình sẵn Plugin Cache, quá trình init diễn ra gần như ngay lập tức.
3. Thông báo xuất hiện: `Terraform has been successfully initialized!`.

---

### 2.4 — Khám phá cấu trúc dự án sau khi Init

Kiểm tra cây thư mục vừa được sinh ra:

```bash
ls -la
```{{exec}}

Xem nội dung của file khóa phụ thuộc vừa được tạo:

```bash
cat .terraform.lock.hcl
```{{exec}}

Bạn sẽ thấy block `provider "registry.terraform.io/hashicorp/aws"` cùng với mã băm bảo mật các nền tảng (Linux, Darwin...).

---

## 3. Bài Tập Thử Thách

Bổ sung thêm thẻ định danh dự án vào cấu hình `default_tags`:

1. Mở file `provider.tf` (hoặc dùng lệnh `sed` / `cat`) để thêm cặp thẻ sau vào block `tags`:
   * **Key:** `Project`
   * **Value:** `devops-lab`
2. Chạy lệnh sau để xác nhận cú pháp file không bị lỗi:
   ```bash
   terraform validate
   ```{{exec}}

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
