# Lab 16: Thực Hành Khởi Tạo Hạ Tầng Cloud Cơ Bản Bằng Terraform CLI

Chào mừng bạn đến với bài thực hành chuyên sâu về **Infrastructure as Code (IaC)** với **Terraform CLI**. Trong bài lab này, bạn sẽ làm chủ quy trình quản trị hạ tầng điện toán đám mây bằng mã nguồn khai báo (Declarative IaC), xây dựng kiến trúc mạng VPC và máy ảo EC2 trên nền tảng **LocalStack** mô phỏng AWS.

---

## 1. Từ ClickOps / Shell Script Đến Infrastructure as Code (IaC)

Ở các bài lab trước, chúng ta đã tiếp cận việc tạo tài nguyên bằng các câu lệnh mệnh lệnh (Imperative) tuần tự của AWS CLI. Mặc dù script hoá được, nhưng cách này bộc lộ những nhược điểm lớn trong môi trường Production:

* **Không lưu vết trạng thái (State-less):** Chạy lại script lần 2 sẽ gây lỗi duplicate tài nguyên hoặc crash hệ thống.
* **Thứ tự phụ thuộc thủ công:** Kỹ sư phải tự nhớ thứ tự tạo (VPC → Subnet → IGW → EC2) và thứ tự xóa ngược lại.
* **Khó quản lý drift:** Không thể dễ dàng so sánh giữa cấu hình mong muốn và thực tế đang chạy trên Cloud.

**Terraform giải quyết triệt để vấn đề này với mô hình Khai Báo (Declarative):** Bạn chỉ cần mô tả *trạng thái mong muốn (Desired State)* trong code, Terraform sẽ tự động tính toán đồ thị phụ thuộc (DAG - Directed Acyclic Graph) để tạo, sửa hoặc xóa tài nguyên một cách tối ưu và an toàn.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  MÔ HÌNH HOẠT ĐỘNG CỦA TERRAFORM                                            │
│                                                                             │
│   [ Code HCL (*.tf) ]        [ terraform.tfstate ]        [ Cloud / LocalStack ]
│   (Desired State)       vs   (Last Known State)     vs   (Actual State)     │
│           │                         │                           │           │
│           └─────────────────────────┼───────────────────────────┘           │
│                                     ▼                                       │
│                       [ terraform plan / apply ]                            │
│                                     │                                       │
│                Tính toán phần chênh lệch (Diff Calculation)                 │
│                + Tạo mới (Create)  ~ Cập nhật (Update)  - Xóa (Destroy)     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến Trúc Hạ Tầng Triển Khai Trong Lab

Bạn sẽ lập trình toàn bộ kiến trúc sau bằng ngôn ngữ HashiCorp Configuration Language (HCL):

```
┌─────────────────────────────────────────────────────────────────────────┐
│  AWS VPC: 10.0.0.0/16 (tf-vpc)                                          │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │ Public Subnet: 10.0.1.0/24 (tf-public-subnet)                     │  │
│  │                                                                   │  │
│  │   ┌───────────────────────────────────────────────────────────┐   │  │
│  │   │ EC2 Instance: t2.micro (tf-web-instance)                  │   │  │
│  │   │                                                           │   │  │
│  │   │ Security Group (tf-web-sg):                               │   │  │
│  │   │ • Inbound: Port 80 (HTTP), Port 22 (SSH)                  │   │  │
│  │   │ • Outbound: Allow All                                     │   │  │
│  │   └─────────────────────────────▲─────────────────────────────┘   │  │
│  └─────────────────────────────────┼─────────────────────────────────┘  │
│                                    │                                    │
│                           Route: 0.0.0.0/0                              │
│                                    ▼                                    │
│                         [ Internet Gateway: tf-igw ]                    │
└────────────────────────────────────┼────────────────────────────────────┘
                                     ▼
                            Internet / Users
```

---

## 3. Vòng Đời Làm Việc Cốt Lõi Với Terraform CLI

Trong suốt bài lab, bạn sẽ làm chủ chu trình 6 lệnh kinh điển của mọi DevOps Engineer:

```
    terraform init      👉 Khởi tạo project, tải provider plugin & tạo lockfile
         │
         ▼
    terraform fmt       👉 Chuẩn hóa định dạng code HCL theo chuẩn cộng đồng
    terraform validate  👉 Kiểm tra tính hợp lệ về cú pháp & tham chiếu biến
         │
         ▼
    terraform plan      👉 Lập kế hoạch thực thi, xem trước các thay đổi (+, ~, -)
         │
         ▼
    terraform apply     👉 Áp dụng thay đổi lên Cloud & cập nhật state file
         │
         ▼
    terraform state     👉 Truy vấn, kiểm tra các thuộc tính trong terraform.tfstate
    terraform show      
         │
         ▼
    terraform destroy   👉 Dọn dẹp sạch sẽ toàn bộ hạ tầng chỉ trong 1 lệnh duy nhất
```

---

## 4. Giao Diện Làm Việc: IDE & Terminal

* Bài lab này được tích hợp giao diện **Theia IDE (Web VS Code)**:
  * **Cây thư mục bên trái (Explorer):** Quan sát trực quan các file mã nguồn `.tf`, thư mục ẩn `.terraform/`, file `.terraform.lock.hcl` và file trạng thái `terraform.tfstate`.
  * **Editor tabs:** Bạn có thể click vào các file bên trái để xem nội dung và chỉnh sửa code trực quan.
  * **Terminal bên dưới:** Thực thi các lệnh `terraform` và `aws`.
* **LocalStack:** Toàn bộ lệnh Terraform sẽ gọi API đến LocalStack tại `http://localhost:4566`, phản hồi tức thì và hoàn toàn miễn phí.
