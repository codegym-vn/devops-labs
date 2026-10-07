# Bước 3: Khắc Phục Toàn Diện Các Vi Phạm An Ninh (Remediation)

Sau khi đã nhận diện các điểm yếu bảo mật từ báo cáo của cả hai công cụ, bạn sẽ tiến hành sửa đổi mã nguồn Terraform (Remediation) để đáp ứng chuẩn an ninh CIS Benchmarks.

---

## 1. Các Tiêu Chuẩn Gia Cố Cần Đạt Được

1. **Gia cố S3 Bucket:**
   * Kích hoạt cơ chế mã hóa phía máy chủ (Server-Side Encryption) chuẩn AES256.
   * Bật tính năng Versioning để bảo vệ dữ liệu chống xóa hoặc ghi đè trái phép.
   * Kích hoạt đầy đủ 4 cờ chặn truy cập công khai trong `aws_s3_bucket_public_access_block`.
2. **Gia cố Security Group:**
   * Loại bỏ dải IP công khai `0.0.0.0/0` ở cổng 22.
   * Giới hạn truy cập SSH chỉ từ dải IP nội bộ doanh nghiệp (ví dụ: `10.0.0.0/16`).

---

## 2. Các Bước Thực Hiện

### 2.1 — Xóa tệp cấu hình cũ và tạo tệp đã gia cố

Xóa tệp cấu hình không an toàn:

```bash
cd /root/iac-security-lab
rm -f insecure_resources.tf
```{{exec}}

Tạo tệp cấu hình chuẩn hóa `secure_resources.tf`:

```bash
cat << 'EOF' > secure_resources.tf
# 1. S3 Bucket dat chuan bao mat CIS
resource "aws_s3_bucket" "financial_data" {
  bucket = "company-financial-records-2026"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.financial_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.financial_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.financial_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Security Group gioi han dai IP noi bo
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssh-sg"
  description = "Security group for bastion host"

  ingress {
    description = "SSH only from internal corporate network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

---

### 2.2 — Kiểm chứng lại bằng Tfsec

Chạy lại `tfsec` để kiểm tra kết quả:

```bash
tfsec .
```{{exec}}

Thông báo in ra: `No problems detected!`, xác nhận toàn bộ các vi phạm nghiêm trọng trước đây đã được giải quyết triệt để.

---

### 2.3 — Kiểm chứng lại bằng Checkov

Chạy kiểm tra chuyên sâu với Checkov:

```bash
checkov -d . --framework terraform --check CKV_AWS_24,CKV_AWS_19,CKV_AWS_21
```{{exec}}

Kết quả hiển thị: `Passed checks: 3, Failed checks: 0`. Toàn bộ các cổng kiểm soát an ninh nguy cấp đều đã vượt qua thành công.

Nhấn **Check** để hoàn thành Bước 3!
