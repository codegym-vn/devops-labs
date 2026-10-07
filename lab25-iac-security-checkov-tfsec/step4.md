# Bước 4: Cấu Hình Bỏ Qua Cảnh Báo Ngoại Lệ Hợp Lệ (Suppression)

Trong môi trường thực tế, không phải mọi cảnh báo an ninh đều đồng nghĩa với lỗi. Có những tình huống nghiệp vụ bắt buộc phải mở cổng công khai (ví dụ máy chủ Web công cộng phải mở cổng HTTP 80 cho người dùng Internet truy cập).

Nếu không có cơ chế xử lý ngoại lệ, pipeline CI/CD sẽ liên tục bị chặn đứng (False Positive). Cả Checkov và Tfsec đều cung cấp kỹ thuật **Suppression** thông qua chú thích dòng lệnh (inline comment) kèm lý do giải trình rõ ràng.

---

## 1. Cú Pháp Bỏ Qua Cảnh Báo Chuẩn Doanh Nghiệp

* **Cú pháp Checkov:**
  `# checkov:skip=<RULE_ID>: <Lý do giải trình chi tiết>`
* **Cú pháp Tfsec:**
  `# tfsec:ignore:<RULE_ID>: <Lý do giải trình chi tiết>`

Quy định bảo mật doanh nghiệp nghiêm cấm bỏ qua cảnh báo mà không có lý do giải trình hợp lệ.

---

## 2. Các Bước Thực Hiện

### 2.1 — Thêm tài nguyên mở cổng 80 kèm chú thích ngoại lệ

Nối cấu hình tài nguyên máy chủ Web công khai vào tệp `secure_resources.tf`:

```bash
cd /root/iac-security-lab
cat << 'EOF' >> secure_resources.tf

# 3. Web HTTP Security Group mo cong 80 hop le
resource "aws_security_group" "public_web_sg" {
  name        = "public-web-sg"
  description = "Allow HTTP inbound traffic for web service"

  # checkov:skip=CKV_AWS_260: Bat buoc mo cong 80 cho nguoi dung internet truy cap website cong cong
  # tfsec:ignore:aws-vpc-no-public-ingress-sgr: Chap thuan mo cong 80 theo yeu cau nghiep vu
  ingress {
    description = "Public HTTP"
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

---

### 2.2 — Kiểm tra cơ chế Suppression với Checkov

Chạy Checkov để kiểm tra cách công cụ nhận diện chú thích bỏ qua:

```bash
checkov -d . --framework terraform
```{{exec}}

Quan sát phần báo cáo ở cuối:
* Mục **Suppressed checks** sẽ liệt kê kiểm tra `CKV_AWS_260` trên tài nguyên `aws_security_group.public_web_sg`.
* Lý do giải trình mà bạn vừa nhập được in ra rõ ràng: `Explanation: Bat buoc mo cong 80 cho nguoi dung internet truy cap website cong cong`.
* Kết quả tổng thể vẫn được đánh giá là ĐẠT (Passed) vì ngoại lệ đã được phê duyệt bằng chú thích hợp lệ.

---

### 2.3 — Kiểm tra với Tfsec

Chạy `tfsec` để xác nhận công cụ không cảnh báo lỗi ở cổng 80:

```bash
tfsec .
```{{exec}}

Tfsec nhận diện từ khóa `tfsec:ignore` và tiếp tục báo `No problems detected!`.

Lưu toàn bộ mã nguồn đạt chuẩn vào Git:

```bash
git add .
git commit -m "feat: hoan tat gia co bao mat va them suppression hop le"
```{{exec}}

Nhấn **Check** để hoàn thành Bước 4!
