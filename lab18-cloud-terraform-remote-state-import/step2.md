# Bước 2: Xử Lý Sự Cố Khóa State & Can Thiệp Bằng State CLI (mv, rm, force-unlock)

Trong bước này, bạn sẽ thực hành xử lý 3 sự cố thường gặp nhất trong vận hành nhóm: **gỡ kẹt khóa trạng thái (`force-unlock`)**, **đổi tên tài nguyên an toàn không gây downtime (`state mv`)**, và **gỡ tài nguyên ra khỏi state mà không xóa trên Cloud (`state rm`)**.

---

## 1. Lý Thuyết: Các Kỹ Thuật Can Thiệp State Nâng Cao

### 1.1 — Sự Cố Kẹt Khóa (Stuck State Lock)
Khi một tiến trình CI/CD đang chạy `terraform apply` thì máy chủ bị mất điện, mạng ngắt đột ngột, hoặc người dùng ấn `Ctrl + C` cưỡng bức:
* Bản ghi LockID trong DynamoDB chưa kịp xóa.
* Tất cả các lần chạy kế tiếp đều bị chặn với thông báo lỗi: `Error acquiring the state lock`.
* **Giải pháp:** Sử dụng lệnh `terraform force-unlock <LOCK_ID>` để giải phóng khóa cưỡng bức sau khi đã xác minh không có ai đang thực sự chạy apply.

### 1.2 — Tái Cấu Trúc An Toàn Với `terraform state mv`
* Nếu bạn đổi tên một resource trong code (ví dụ đổi `aws_vpc.core` → `aws_vpc.main`):
  * Terraform mặc định sẽ: **Xóa (Destroy)** VPC cũ và **Tạo mới (Create)** VPC mới! Toàn bộ máy chủ, cơ sở dữ liệu bên trong VPC sẽ bị xóa sổ.
* Lệnh `terraform state mv <Nguon> <Dich>` cho phép bạn cập nhật ánh xạ định danh trong State File mà **không gửi bất kỳ lệnh xóa nào lên Cloud**.

### 1.3 — Tách Quyền Quản Lý Với `terraform state rm`
Khi bạn muốn chuyển giao một tài nguyên (VPC, Subnet, Database) cho một team khác quản lý, hoặc muốn xóa code `.tf` đi nhưng **giữ nguyên tài nguyên đang chạy trên Cloud**, hãy dùng `terraform state rm`.

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-remote-lab`.

### 2.1 — Giả lập sự cố kẹt khóa & Cứu hộ bằng `terraform force-unlock`

1. **Tạo tình huống kẹt khóa giả lập bằng AWS CLI:**
   Chèn một bản ghi Lock giả vào bảng DynamoDB:
   ```bash
   aws dynamodb put-item \
     --table-name devops-tfstate-locks \
     --item '{
       "LockID": {"S": "devops-tfstate-bucket/network/terraform.tfstate-md5"},
       "Info": {"S": "{\"ID\":\"mock-lock-9999\",\"Operation\":\"OperationTypeApply\",\"Who\":\"ci-pipeline-crash\",\"Version\":\"1.9.5\"}"}
     }'
   ```{{exec}}

2. **Chạy thử lệnh `terraform plan` để quan sát lỗi:**
   ```bash
   terraform plan
   ```{{exec}}
   *Thông báo lỗi xuất hiện:*
   `Error: Error acquiring the state lock`
   `Lock Info: ID: mock-lock-9999, Who: ci-pipeline-crash...`

3. **Cứu hộ giải phóng khóa với `terraform force-unlock`:**
   ```bash
   terraform force-unlock -force mock-lock-9999
   ```{{exec}}

4. **Kiểm tra lại:**
   ```bash
   terraform plan
   ```{{exec}}
   *Lệnh plan đã hoạt động trở lại bình thường và mượt mà!*

---

### 2.2 — Đổi tên Resource an toàn không gây Downtime (`state mv`)

1. **Sửa code HCL trong `main.tf`:**
   Đổi tên cục bộ của VPC từ `"core"` sang `"main"`:
   ```bash
   cat << 'EOF' > main.tf
   resource "aws_vpc" "main" {
     cidr_block           = "10.0.0.0/16"
     enable_dns_hostnames = true

     tags = {
       Name = "core-vpc"
     }
   }
   EOF
   ```{{exec}}

2. **Chạy `terraform plan` để xem nguy cơ:**
   ```bash
   terraform plan
   ```{{exec}}
   *Nguy hiểm:* Terraform báo `Plan: 1 to add, 0 to change, 1 to destroy.` (Sẽ xóa VPC cũ và tạo VPC mới!).

3. **Thực thi di chuyển ánh xạ trong State:**
   ```bash
   terraform state mv aws_vpc.core aws_vpc.main
   ```{{exec}}
   *Thông báo:* `Move "aws_vpc.core" to "aws_vpc.main"` - `Successfully moved 1 object(s).`

4. **Kiểm tra lại kế hoạch:**
   ```bash
   terraform plan
   ```{{exec}}
   *Kết quả tuyệt vời:* `No changes. Your infrastructure matches the configuration.` Hạ tầng giữ nguyên 100%, không hề có downtime!

---

## 3. Bài Tập Thử Thách: Tách Tài Nguyên Khỏi State Với `state rm`

Team Network muốn tự quản lý một Subnet thử nghiệm và yêu cầu Terraform gỡ subnet này ra khỏi State mà không được xóa trên Cloud:

1. Thêm subnet mới vào cuối file `main.tf`:
   ```bash
   cat << 'EOF' >> main.tf

   resource "aws_subnet" "test_subnet" {
     vpc_id     = aws_vpc.main.id
     cidr_block = "10.0.99.0/24"

     tags = {
       Name = "untracked-subnet"
     }
   }
   EOF
   ```{{exec}}
2. Chạy apply để tạo subnet lên Cloud:
   ```bash
   terraform apply -auto-approve
   ```{{exec}}
3. Bây giờ, thực hiện gỡ subnet này ra khỏi State bằng lệnh:
   ```bash
   terraform state rm aws_subnet.test_subnet
   ```{{exec}}
4. Xóa khối code `resource "aws_subnet" "test_subnet"` vừa thêm khỏi `main.tf` (hoặc dùng `git checkout main.tf` để giữ lại chỉ `aws_vpc.main`).
5. Kiểm tra đối chứng:
   * `terraform state list` (xác nhận không còn `aws_subnet.test_subnet`).
   * Dùng AWS CLI:
     ```bash
     aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.0.99.0/24" --output table
     ```{{exec}}
     *(Subnet vẫn đang tồn tại nguyên vẹn trên Cloud!)*

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và chấm điểm tự động.
