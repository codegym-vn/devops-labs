# Bước 1: Khám Phá Mã Nguồn Hạ Tầng & Quét Nhanh Với Tfsec

Trong bước đầu tiên, bạn sẽ khám phá mã nguồn Terraform mẫu đang chứa các lỗ hổng cấu hình nghiêm trọng, sau đó sử dụng công cụ `tfsec` để quét nhanh và trích xuất báo cáo an ninh.

---

## 1. Khám Phá Các Tệp Cấu Hình Terraform

Di chuyển vào thư mục làm việc và quan sát cấu trúc:

```bash
cd /root/iac-security-lab
ls -la
```{{exec}}

Kiểm tra nội dung tệp `insecure_resources.tf`:

```bash
cat /root/iac-security-lab/insecure_resources.tf
```{{exec}}

Phân tích các rủi ro bảo mật tiềm ẩn trong tệp này:
1. `aws_s3_bucket.financial_data`: Lưu trữ dữ liệu tài chính nhạy cảm nhưng không có cấu hình mã hóa phía máy chủ (Server-side Encryption) và không bật Versioning.
2. `aws_s3_bucket_public_access_block`: Đặt toàn bộ các cờ ngăn chặn công khai thành `false`, tạo nguy cơ dữ liệu bị rò rỉ ra Internet.
3. `aws_security_group.bastion_sg`: Mở cổng SSH 22 cho toàn bộ dải IP `0.0.0.0/0`, tạo điều kiện cho các cuộc tấn công dò mật khẩu tự động (Brute-force).

---

## 2. Thực Thi Quét Nhanh Với Tfsec

Chạy công cụ `tfsec` trên thư mục hiện tại:

```bash
tfsec .
```{{exec}}

Quan sát bảng kết quả:
* `CRITICAL`: Mở cổng nhạy cảm 22 ra ngoài Internet (`aws-vpc-no-public-ingress-sgr`).
* `HIGH`: S3 Bucket không bật mã hóa dữ liệu at-rest (`aws-s3-enable-bucket-encryption`).
* `HIGH`: Không chặn các ACL công khai trên S3 Bucket (`aws-s3-block-public-acls`).
* `MEDIUM`: S3 Bucket không bật cơ chế lưu trữ phiên bản (`aws-s3-enable-versioning`).

Mỗi lỗi hiển thị rõ số dòng vi phạm, nguyên nhân rủi ro và mã quy tắc tương ứng.

---

## 3. Xuất Báo Cáo Định Dạng JSON

Để tích hợp với các hệ thống phân tích hoặc lưu trữ làm bằng chứng kiểm toán (Audit Trail), chạy lệnh xuất kết quả ra tệp JSON:

```bash
tfsec . --format json --out tfsec-report.json
```{{exec}}

Kiểm tra tệp báo cáo vừa sinh ra:

```bash
cat tfsec-report.json | grep -E "rule_id|severity" | head -n 12
```{{exec}}

Nhấn **Check** để hoàn thành Bước 1!
