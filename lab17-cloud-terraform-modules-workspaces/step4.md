# Bước 4: Triển Khai Môi Trường Prod, Kiểm Thử Cô Lập & Dọn Dẹp

Trong bước cuối cùng này, bạn sẽ tạo Workspace **Production**, triển khai hạ tầng Prod với cấu hình quy mô lớn hơn, kiểm chứng tính cô lập tuyệt đối giữa hai môi trường và thực hiện quy trình dọn dẹp tài nguyên an toàn.

---

## 1. Lý Thuyết: Tính Cô Lập Hạ Tầng (Side-by-Side Coexistence)

Khi bạn chuyển đổi giữa các Workspaces:
1. **Trạng thái độc lập:** Terraform trỏ con trỏ state file sang vùng nhớ tương ứng. Khi ở Workspace `prod`, Terraform hoàn toàn không "nhìn thấy" máy ảo hay VPC của `dev`.
2. **Triển khai song song:** Hai hệ thống mạng và cụm máy chủ chạy song song trên cùng một Cloud:
   * `dev`: CIDR `10.10.0.0/16`, máy ảo `t2.micro`
   * `prod`: CIDR `10.20.0.0/16`, máy ảo `t2.small`
3. **Dọn dẹp có chọn lọc:** Chạy `terraform destroy` ở Workspace `prod` sẽ **chỉ xóa tài nguyên của Prod**, bảo toàn 100% môi trường `dev` đang chạy!

---

## 2. Thực Hành

Đảm bảo bạn đang ở thư mục `/root/terraform-workspaces-lab`.

### 2.1 — Khởi tạo Workspace `prod` và triển khai hạ tầng

1. **Tạo và chuyển sang Workspace `prod`:**
   ```bash
   terraform workspace new prod
   ```{{exec}}

2. **Lập kế hoạch triển khai cho Production:**
   ```bash
   terraform plan -var-file=environments/prod.tfvars -out=prod.tfplan
   ```{{exec}}

3. **Áp dụng kế hoạch Prod:**
   ```bash
   terraform apply prod.tfplan
   ```{{exec}}

---

### 2.2 — Xác minh tính cô lập & chạy song song (Coexistence)

Sau khi apply xong, hãy kiểm tra trên Cloud bằng AWS CLI:

1. **Kiểm tra cả 2 mạng VPC cùng tồn tại:**
   ```bash
   aws ec2 describe-vpcs \
     --query "Vpcs[*].[Tags[?Key=='Name'].Value|[0],CidrBlock,VpcId]" \
     --output table
   ```{{exec}}
   *Bạn sẽ thấy cả `dev-vpc` (10.10.0.0/16) và `prod-vpc` (10.20.0.0/16) hiển thị song song.*

2. **Kiểm tra cả 2 máy chủ EC2 với cấu hình phần cứng khác nhau:**
   ```bash
   aws ec2 describe-instances \
     --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value|[0],InstanceType,PrivateIpAddress,State.Name]" \
     --output table
   ```{{exec}}
   * `dev-web-server`: loại `t2.micro`, IP thuộc dải `10.10.1.x`.
   * `prod-web-server`: loại `t2.small`, IP thuộc dải `10.20.1.x`.

---

### 2.3 — Chuyển đổi linh hoạt giữa các Workspace

Thử nghiệm chuyển đổi qua lại để thấy rõ sự cô lập của State:

```bash
# Xem state khi đang ở prod:
terraform state list

# Chuyển về dev:
terraform workspace select dev

# Xem state khi đang ở dev:
terraform state list
```{{exec}}

Mỗi không gian chỉ hiển thị chính xác các tài nguyên thuộc về môi trường đó!

---

### 2.4 — Dọn dẹp tài nguyên Production có chọn lọc

Chuyển sang `prod` và thực hiện hủy chỉ riêng môi trường Production:

```bash
terraform workspace select prod
terraform destroy -var-file=environments/prod.tfvars -auto-approve
```{{exec}}

Kiểm tra lại danh sách VPC trên Cloud:

```bash
aws ec2 describe-vpcs \
  --query "Vpcs[*].[Tags[?Key=='Name'].Value|[0],CidrBlock]" \
  --output table
```{{exec}}

*Kết quả:* `prod-vpc` đã bị xóa hoàn toàn sạch sẽ, trong khi `dev-vpc` vẫn còn nguyên vẹn và đang chạy ổn định!

---

## 3. Bài Tập Thử Thách

Hoàn thành quy trình dọn dẹp sạch sẽ toàn bộ môi trường phòng lab:

1. Chuyển về Workspace `dev` và dọn dẹp nốt hạ tầng môi trường Dev:
   ```bash
   terraform workspace select dev
   terraform destroy -var-file=environments/dev.tfvars -auto-approve
   ```{{exec}}
2. Chuyển về Workspace mặc định (`default`):
   ```bash
   terraform workspace select default
   ```{{exec}}
3. Xóa hai Workspace `dev` và `prod` đã dọn dẹp:
   ```bash
   terraform workspace delete dev
   terraform workspace delete prod
   ```{{exec}}
4. Chạy `terraform workspace list` để xác nhận chỉ còn lại duy nhất `* default`.

> Nhấn nút **Check** ở góc dưới để hệ thống kiểm tra và hoàn thành toàn bộ bài lab.
