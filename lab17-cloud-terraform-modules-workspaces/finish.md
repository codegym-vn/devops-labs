# 🏆 Chúc Mừng! Bạn Đã Hoàn Thành Lab 17: Terraform Modules & Workspaces

Bạn vừa làm chủ thành công hai kỹ thuật quan trọng nhất trong việc quản trị hạ tầng Terraform ở quy mô doanh nghiệp: **Đóng gói Modules tái sử dụng** và **Triển khai đa môi trường độc lập với Workspaces**!

---

## 1. Tóm Tắt Kiến Trúc Doanh Nghiệp Đã Xây Dựng

```text
 1. Cấu Trúc Module Chuẩn Mực:
    modules/vpc/     ──► Đóng gói VPC, Subnet, IGW, Route Table (Giao tiếp qua variables & outputs)
    modules/compute/ ──► Đóng gói Security Group, EC2 Instance (Nhận subnet_id, vpc_id từ module vpc)
    Root (main.tf)   ──► "Nhạc trưởng" điều phối, liên kết dữ liệu giữa các child modules

 2. Quản Trị Đa Môi Trường Độc Lập:
    environments/dev.tfvars  ──► Cấu hình Dev  (CIDR 10.10.0.0/16, EC2 t2.micro)
    environments/prod.tfvars ──► Cấu hình Prod (CIDR 10.20.0.0/16, EC2 t2.small)

 3. Cô Lập Trạng Thái Hạ Tầng:
    terraform.tfstate.d/dev/  ──► Lưu vết riêng biệt hạ tầng Development
    terraform.tfstate.d/prod/ ──► Lưu vết riêng biệt hạ tầng Production
    Coexistence               ──► Hai cụm hạ tầng chạy song song, dọn dẹp độc lập không ảnh hưởng lẫn nhau
```

---

## 2. Bảng Tra Cứu Lệnh Quản Trị Workspaces & Modules (Cheat Sheet)

| Lệnh | Mục Đích Sử Dụng Thực Tế | Tình Huống Áp Dụng |
| :--- | :--- | :--- |
| `terraform init` | Tải provider và đăng ký/cập nhật cây Child Modules | Bắt buộc chạy khi thêm khối `module` mới vào mã nguồn |
| `terraform fmt -recursive` | Tự động định dạng toàn bộ file trong Root và các Child Modules | Chuẩn hóa toàn bộ codebase trước khi tạo Pull Request |
| `terraform workspace list` | Liệt kê tất cả các workspace và đánh dấu workspace hiện tại | Kiểm tra không gian làm việc đang active trước khi thao tác |
| `terraform workspace new <name>` | Tạo một không gian làm việc mới và tự động chuyển sang đó | Khởi tạo môi trường mới (`staging`, `prod`, `qa`) |
| `terraform workspace select <name>` | Chuyển đổi con trỏ ngữ cảnh làm việc giữa các môi trường | Chuyển qua lại giữa `dev` và `prod` để kiểm tra hoặc cập nhật |
| `terraform workspace show` | Hiển thị tên workspace hiện tại đang active | Kiểm tra nhanh ngữ cảnh trong script CI/CD |
| `terraform workspace delete <name>` | Xóa bỏ một workspace rỗng đã dọn dẹp | Dọn dẹp sau khi đã chạy `terraform destroy` hết tài nguyên |
| `terraform plan -var-file=<path>` | Lập kế hoạch thực thi nạp file thông số môi trường tương ứng | Đối chiếu plan cho từng môi trường cụ thể |
| `terraform apply -var-file=<path>` | Triển khai hạ tầng áp dụng file cấu hình môi trường | Đẩy cấu hình lên Cloud theo workspace đang chọn |

---

## 3. Câu Hỏi Phỏng Vấn DevOps / SRE Thường Gặp

1. **Khi nào nên sử dụng Terraform Workspaces và khi nào nên chia thành các thư mục cấu hình riêng biệt (Directory-based Environments)?**
   * *Trả lời:* 
     * **Nên dùng Workspaces khi:** Các môi trường có kiến trúc hạ tầng giống hệt nhau 95-100% (cùng VPC, cùng cấu trúc compute, chỉ khác tham số về kích thước máy ảo, CIDR, hoặc số lượng replica).
     * **Nên dùng Directory-based (hoặc Terragrunt) khi:** Môi trường Production và Development có sự khác biệt lớn về kiến trúc (ví dụ: Prod dùng Multi-Region, transit gateway, tài khoản AWS riêng biệt với quyền truy cập IAM hoàn toàn cách ly).

2. **Làm thế nào để truyền dữ liệu từ Child Module này sang Child Module khác trong Root Module?**
   * *Trả lời:*
     * Bước 1: Trong Child Module nguồn (ví dụ: `modules/vpc`), khai báo khối `output "vpc_id" { value = aws_vpc.this.id }`.
     * Bước 2: Trong Child Module đích (ví dụ: `modules/compute`), khai báo biến nhận `variable "vpc_id" {}`.
     * Bước 3: Tại Root Module (`main.tf`), gán giá trị output của module nguồn vào tham số đầu vào của module đích: `vpc_id = module.vpc.vpc_id`.

3. **Điều gì sẽ xảy ra nếu bạn cố gắng xóa một Workspace đang chứa tài nguyên (`terraform workspace delete dev`)?**
   * *Trả lời:* Terraform sẽ chặn lại ngay lập tức và báo lỗi: Workspace không rỗng vì file state của nó vẫn đang theo dõi các tài nguyên thực tế trên Cloud. Bạn **bắt buộc** phải chuyển sang workspace đó và chạy `terraform destroy` để giải phóng toàn bộ tài nguyên trước khi có thể thực hiện xóa workspace.
