# Bước 2: Quét Phân Tích Chuyên Sâu Chuẩn CIS Benchmarks Với Checkov

Checkov là công cụ quét an ninh toàn diện được phát triển bởi Bridgecrew (Palo Alto Networks). Khác với các công cụ chỉ kiểm tra cú pháp, Checkov tích hợp hàng trăm chính sách tuân thủ theo các tiêu chuẩn quốc tế như **CIS AWS Foundations Benchmark**, **NIST** và **PCI-DSS**.

---

## 1. Thực Thi Quét Toàn Diện Với Checkov

Chạy Checkov quét toàn bộ các tệp Terraform trong thư mục hiện tại:

```bash
cd /root/iac-security-lab
checkov -d . --framework terraform
```{{exec}}

Quan sát cấu trúc báo cáo của Checkov:
* **Passed checks:** Danh sách các kiểm tra đạt chuẩn.
* **Failed checks:** Danh sách chi tiết các vi phạm:
  * `CKV_AWS_24`: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22".
  * `CKV_AWS_19`: "Ensure all data stored in the S3 bucket is securely encrypted at rest".
  * `CKV_AWS_21`: "Ensure all data stored in the S3 bucket has versioning enabled".
  * `CKV_AWS_53`: "Ensure S3 bucket has block public acls enabled".
* Mỗi lỗi đều hiển thị đoạn mã vi phạm (Code snippet) và đường dẫn tài liệu hướng dẫn khắc phục chính thức.

---

## 2. Kỹ Thuật Lọc Check Theo Mức Độ & Cổng Kiểm Soát

Trong quy trình tự động hóa (CI/CD Pipeline), nếu dự án có quá nhiều cảnh báo nhỏ, ta có thể thiết lập Checkov chỉ tập trung vào các lỗi nghiêm trọng nhất bằng cờ `--check`:

```bash
checkov -d . --framework terraform --check CKV_AWS_24,CKV_AWS_19
```{{exec}}

Lệnh này sẽ quét và chỉ đánh trượt nếu hai lỗi nguy cấp trên chưa được xử lý.

---

## 3. Xuất Báo Cáo Phân Tích Checkov Dạng JSON

Xuất toàn bộ kết quả phân tích ra tệp JSON để phục vụ lưu trữ:

```bash
checkov -d . --framework terraform -o json > checkov-report.json
```{{exec}}

Kiểm tra số lượng vi phạm được ghi nhận:

```bash
cat checkov-report.json | grep -o '"check_id": "CKV_AWS_[0-9]*"' | head -n 6
```{{exec}}

Nhấn **Check** để hoàn thành Bước 2!
