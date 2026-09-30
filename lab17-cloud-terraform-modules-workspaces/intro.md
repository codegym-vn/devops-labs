# Lab 17: Thực Hành Đóng Gói Terraform Module & Triển Khai Đa Môi Trường Với Workspaces

Chào mừng bạn đến với bài thực hành nâng cao về **Kiến trúc Terraform chuẩn Enterprise**. Trong bài lab này, bạn sẽ giải quyết hai bài toán kinh điển trong quản trị hạ tầng quy mô lớn: **Đóng gói tái sử dụng (Terraform Modules)** và **Quản lý đa môi trường (Terraform Workspaces)** trên nền tảng **LocalStack**.

---

## 1. Vấn Nạn Code Đơn Khối (Monolith) & Đa Môi Trường

Trong thực tế doanh nghiệp:
* **Nếu viết code đơn lẻ (Monolithic):** Tất cả tài nguyên (mạng, database, máy chủ) dồn vào một file `main.tf` khổng lồ khiến mã nguồn khó đọc, không thể chia sẻ cho các dự án khác, và nguy cơ lỗi dây chuyền cực kỳ cao.
* **Nếu copy-paste thư mục cho từng môi trường:** Tạo thư mục `environments/dev/` và `environments/prod/` rồi copy code qua lại sẽ dẫn đến tình trạng "lệch cấu hình" (Configuration Drift) khi một bên được cập nhật nhưng bên kia bị bỏ quên.

**Giải pháp chuẩn mực của DevOps:**
1. **Terraform Modules:** Đóng gói các tài nguyên liên quan chặt chẽ thành các khối độc lập (Black Box). Giao tiếp với bên ngoài chỉ qua hai cổng: **Biến đầu vào (`variables.tf`)** và **Giá trị trả về (`outputs.tf`)**.
2. **Terraform Workspaces:** Sử dụng đúng **duy nhất 1 bộ mã nguồn (Single Codebase)** nhưng tự động phân tách thành các không gian làm việc độc lập. Mỗi Workspace sở hữu một file trạng thái (`tfstate`) riêng biệt!

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KIẾN TRÚC MÔ ĐUN & WORKSPACES ĐA MÔI TRƯỜNG                                │
│                                                                             │
│                  [ Root Module (main.tf) ]                                  │
│                  • Gọi module "vpc"                                         │
│                  • Gọi module "compute" (nhận output từ vpc)                │
│                               │                                             │
│               ┌───────────────┴───────────────┐                             │
│               ▼                               ▼                             │
│   [ modules/vpc ]                    [ modules/compute ]                    │
│   (VPC, Subnet, IGW, Route)          (Security Group, EC2 Instance)         │
│                                                                             │
│  ═════════════════════════════════════════════════════════════════════════  │
│  CÔ LẬP TRẠNG THÁI BẰNG TERRAFORM WORKSPACES                                │
│                                                                             │
│   Workspace "dev"      ──►  terraform.tfstate.d/dev/terraform.tfstate       │
│   (CIDR: 10.10.0.0/16, t2.micro)  ──►  dev-vpc, dev-web-server              │
│                                                                             │
│   Workspace "prod"     ──►  terraform.tfstate.d/prod/terraform.tfstate      │
│   (CIDR: 10.20.0.0/16, t2.small)  ──►  prod-vpc, prod-web-server            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến Trúc Thư Mục Chuẩn Doanh Nghiệp

Bạn sẽ thiết kế và cấu trúc thư mục dự án theo đúng chuẩn Best Practices:

```text
terraform-workspaces-lab/
├── environments/
│   ├── dev.tfvars           # Tham số môi trường Development (IP nhỏ, VM nhỏ)
│   └── prod.tfvars          # Tham số môi trường Production (IP lớn, VM lớn)
├── modules/
│   ├── vpc/                 # Child module quản trị mạng
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/             # Child module quản trị compute & firewall
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                  # Root module kết nối các child modules
├── variables.tf             # Biến toàn cục của Root module
├── outputs.tf               # Đầu ra tổng hợp của toàn hệ thống
├── provider.tf              # Cấu hình AWS Provider kết nối LocalStack
└── versions.tf              # Ràng buộc phiên bản Core và Provider
```

---

## 3. Mục Tiêu Học Tập

Sau khi hoàn thành bài lab này, bạn có khả năng:
* **Phân tách và đóng gói** cấu hình Terraform đơn lẻ thành cấu trúc Terraform Module có tính tái sử dụng cao, chuẩn hóa giao diện tương tác qua biến đầu vào (`variables.tf`) và giá trị trả về (`outputs.tf`).
* **Vận dụng** cơ chế Terraform Workspaces để quản lý và cô lập trạng thái hạ tầng (`tfstate`) giữa các môi trường khác nhau (`dev`, `prod`) trên cùng một bộ mã nguồn.
* **Cấu hình linh hoạt** các tham số hạ tầng (như quy mô máy ảo, IP range) tương ứng với từng môi trường thông qua việc kết hợp Workspaces và các file biến môi trường (`.tfvars`).
* **Thực thi** quy trình kiểm thử triển khai độc lập, chuyển đổi qua lại giữa các Workspaces và xác minh tính cô lập của tài nguyên thực tế.
