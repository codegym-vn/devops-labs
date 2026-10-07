# Hoàn Thành Bài Lab 25: Quét Lỗ Hổng Bảo Mật Mã Nguồn Terraform

Xin chúc mừng! Bạn đã hoàn thành xuất sắc bài thực hành kiểm thử an ninh tĩnh (SAST) cho hạ tầng dưới dạng mã nguồn (IaC).

---

## 1. Tổng Kết Các Kỹ Năng Đã Đạt Được

1. **Thực Thi Phân Tích Tĩnh Mã Nguồn Terraform:**
   * Sử dụng `tfsec` để quét nhanh tức thì trong quá trình phát triển mã cục bộ.
   * Sử dụng `checkov` để phân tích sâu rộng theo các tiêu chuẩn quốc tế (CIS Benchmarks).

2. **Kỹ Năng Khắc Phục Lỗ Hổng Hạ Tầng (Remediation):**
   * Hiểu rõ cách cấu hình mã hóa Server-Side Encryption (AES256) và cơ chế lưu trữ phiên bản (Versioning) trên S3 Bucket.
   * Thiết lập lớp bảo vệ Public Access Block ngăn chặn triệt để rò rỉ dữ liệu.
   * Áp dụng nguyên tắc đặc quyền tối thiểu (Least Privilege) cho Security Group: không bao giờ mở cổng quản trị (SSH/RDP) cho `0.0.0.0/0`.

3. **Quản Trị Rủi Ro & Ngoại Lệ (Suppression):**
   * Áp dụng cú pháp chú thích dòng lệnh (`checkov:skip` và `tfsec:ignore`) kèm lý do giải trình rõ ràng.
   * Phân biệt rõ giữa bỏ qua có kiểm soát và bỏ qua tùy tiện gây nguy cơ an ninh.

---

## 2. Checklist Bảo Mật Cho Dự Án Terraform Thực Tế

| Tài nguyên | Quy chuẩn an ninh bắt buộc |
|---|---|
| **S3 Bucket** | Luôn bật SSE (KMS/AES256), Versioning và Public Access Block = true |
| **Security Group** | Không mở cổng 22, 3389, 3306, 5432 ra `0.0.0.0/0` |
| **RDS Database** | Bật mã hóa lưu trữ (`storage_encrypted = true`), đặt trong Private Subnet |
| **EBS Volume** | Luôn kích hoạt mã hóa ổ đĩa (`encrypted = true`) |
| **CI/CD Pipeline** | Tích hợp Checkov làm cổng kiểm tra bắt buộc trước khi `terraform apply` |

---

Bạn có thể tiếp tục tự do khám phá môi trường hoặc đóng kịch bản bài học. Chúc bạn ứng dụng thành công các nguyên lý DevSecOps vào dự án thực tế!
