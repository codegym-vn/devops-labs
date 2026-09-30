# 🏆 Chúc Mừng! Bạn Đã Hoàn Thành Lab 16: Terraform CLI & Cloud IaC

Bạn vừa hoàn thành xuất sắc bài thực hành **Khởi tạo và quản trị hạ tầng Cloud bằng Terraform CLI** trên môi trường giả lập **LocalStack**!

---

## 1. Tóm Tắt Toàn Bộ Kiến Thức Đã Đạt Được

```text
 1. Thiết Lập Dự Án Chuẩn Mực:
    versions.tf ────────► Ràng buộc phiên bản Core và AWS Provider (~> 5.0)
    provider.tf ────────► Cấu hình LocalStack endpoints & gán default_tags tự động
    .terraform.lock.hcl ► Khóa cứng checksum bảo vệ pipeline CI/CD

 2. Kiến Trúc Mạng & Compute Bằng HCL:
    variables.tf ───────► Tham số hóa CIDR block, môi trường (DRY principle)
    vpc.tf ─────────────► VPC, Public Subnet, Private Subnet, IGW & Route Table
    compute.tf ─────────► Security Group (80, 443, 22) & EC2 Web Server
    outputs.tf ─────────► Trích xuất ID và IP phục vụ tích hợp downstream

 3. Vận Hành Vòng Đời & Quản Trị Trạng Thái:
    terraform plan -out ► Lưu kế hoạch nhị phân loại bỏ rủi ro race condition
    terraform apply ────► Khởi tạo đồng thời 8 tài nguyên theo đồ thị DAG
    terraform.tfstate ──► Quản lý mapping giữa mã HCL và Cloud Provider ID
    terraform destroy ──► Tự động dọn dẹp sạch sẽ theo chiều ngược thứ tự phụ thuộc
```

---

## 2. Bảng Tra Cứu Lệnh Terraform CLI (DevOps Cheat Sheet)

| Lệnh | Ý Nghĩa Vận Hành Thực Tế | Tình Huống Sử Dụng |
| :--- | :--- | :--- |
| `terraform init` | Tải provider plugins, module và khởi tạo lockfile | Bắt buộc chạy đầu tiên khi clone repo hoặc đổi provider |
| `terraform fmt` | Tự động định dạng code HCL theo quy chuẩn chung | Chạy trước khi commit code hoặc trong Git pre-commit hook |
| `terraform validate` | Kiểm tra tính hợp lệ về cú pháp và kiểu dữ liệu | Chạy trong pipeline CI để phát hiện lỗi sớm mà không cần kết nối cloud |
| `terraform plan -out=<file>` | Lập kế hoạch thực thi và lưu vào file nhị phân | Dùng trong Pull Request review để đối chiếu chênh lệch hạ tầng |
| `terraform apply <file>` | Áp dụng kế hoạch thực thi lên môi trường Cloud | Triển khai hạ tầng sau khi plan đã được phê duyệt |
| `terraform state list` | Liệt kê tất cả tài nguyên đang được theo dõi | Kiểm tra nhanh các resource đang tồn tại trong state |
| `terraform state show <res>` | Xem toàn bộ thuộc tính chi tiết của một tài nguyên | Điều tra thông số mạng, ID, ARN khi debug lỗi |
| `terraform output` | Xuất các giá trị đầu ra được khai báo trong `outputs.tf` | Lấy IP hoặc ID để chuyển tiếp sang Ansible hoặc Kubernetes |
| `terraform destroy` | Hủy toàn bộ tài nguyên theo thứ tự phụ thuộc an toàn | Dọn dẹp môi trường dev/staging sau khi test xong để tiết kiệm chi phí |

---

## 3. Câu Hỏi Phỏng Vấn DevOps & Cloud Thường Gặp Về Terraform

1. **State File trong Terraform có vai trò gì và tại sao không nên lưu trữ cục bộ (Local State)?**
   * *Trả lời:* State file (`terraform.tfstate`) đóng vai trò là nguồn chân lý duy nhất (Single Source of Truth), ánh xạ các định danh khai báo trong code HCL với các tài nguyên thực tế trên Cloud. Nếu lưu cục bộ:
     * Nhiều kỹ sư cùng làm việc sẽ làm mất đồng bộ state, gây xung đột và ghi đè hạ tầng.
     * State file có thể chứa dữ liệu nhạy cảm (sensitive passwords, private keys) dạng văn bản thuần.
     * *Giải pháp chuẩn Production:* Sử dụng **Remote Backend** (như AWS S3 lưu state với mã hóa SSE-KMS kết hợp AWS DynamoDB để khóa trạng thái - State Locking).

2. **Sự khác nhau giữa `~ update in-place` và `-/+ replace` trong Terraform là gì?**
   * *Trả lời:*
     * `~ update in-place`: Cập nhật các thuộc tính linh hoạt (metadata, tags, rules tường lửa...) trực tiếp thông qua API PATCH/PUT của Cloud mà không xóa tài nguyên, không gây downtime.
     * `-/+ replace`: Xảy ra khi thay đổi các thuộc tính bất biến (ví dụ: `ami`, `subnet_id` của EC2 hoặc `cidr_block` của VPC). Cloud provider không cho sửa tại chỗ nên Terraform bắt buộc phải xóa tài nguyên cũ trước, sau đó mới tạo tài nguyên mới thay thế.

3. **Khi ai đó sửa đổi tài nguyên trực tiếp trên AWS Console (ClickOps) khiến hạ tầng bị lệch (Drift), Terraform xử lý ra sao?**
   * *Trả lời:* Khi bạn chạy `terraform plan`, Terraform tự động thực hiện bước **Refresh** (gọi API AWS để đọc trạng thái thực tế mới nhất) → đối chiếu với file code HCL → phát hiện ra sự chênh lệch (Configuration Drift). Nếu bạn chạy `terraform apply`, Terraform sẽ tự động ghi đè cấu hình trên Cloud để đưa tài nguyên quay trở về đúng trạng thái mong muốn (Desired State) như đã định nghĩa trong mã nguồn.
