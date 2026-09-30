# Lab 18: Cấu Hình Remote Backend, Khôi Phục Sự Cố State & Import Hạ Tầng Sẵn Có

Chào mừng bạn đến với bài thực hành chuyên sâu về **Quản trị trạng thái nâng cao (Advanced State Management)** và **Hiện đại hóa hạ tầng (Brownfield Infrastructure Adoption)** trong Terraform trên nền tảng **LocalStack**.

---

## 1. Vấn Nạn Local State & Thách Thức Vận Hành Nhóm

Khi một dự án DevOps mở rộng quy mô từ một cá nhân sang đội ngũ kỹ sư:
* **Hiểm họa ghi đè đồng thời (Race Condition):** Nếu hai kỹ sư cùng chạy `terraform apply` tại một thời điểm, file state cục bộ sẽ bị xung đột, dẫn đến mất dữ liệu hoặc hạ tầng bị hủy hoại.
* **Lộ lọt thông tin nhạy cảm:** File `terraform.tfstate` cục bộ chứa mật khẩu, private key và token dạng văn bản thuần (plaintext) trên máy tính cá nhân.
* **Hạ tầng di sản (Legacy Infrastructure):** Doanh nghiệp luôn có sẵn những máy ảo, VPC, Security Group được tạo thủ công bằng tay (ClickOps) từ trước. Làm sao đưa chúng vào quản lý bằng mã nguồn IaC mà **không phải xóa đi tạo lại**?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KIẾN TRÚC REMOTE BACKEND & KHÓA TRẠNG THÁI (STATE LOCKING)                 │
│                                                                             │
│   Dev A  ───┐                                                               │
│             ├──► [ Terraform CLI ]                                          │
│   Dev B  ───┘           │                                                   │
│                         ▼                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ 1. Xin cấp quyền khóa (Lock Acquisition):                           │   │
│   │    Ghi LockID vào AWS DynamoDB Table (devops-tfstate-locks)         │   │
│   │                                                                     │   │
│   │ 2. Đọc & Ghi Trạng Thái (Read/Write State):                         │   │
│   │    Tải/Lưu file terraform.tfstate lên AWS S3 Bucket mã hóa an toàn  │   │
│   │                                                                     │   │
│   │ 3. Giải phóng khóa (Lock Release):                                  │   │
│   │    Xóa LockID khỏi DynamoDB sau khi apply hoàn tất                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Kịch Bản Bài Lab

Trong bài thực hành này, bạn sẽ trực tiếp giải quyết 3 bài toán lớn nhất của một DevOps Engineer:
1. **Di chuyển trạng thái (State Migration):** Khởi tạo từ Local State, sau đó cấu hình Remote Backend trên **AWS S3** và **DynamoDB** để di chuyển toàn bộ state lên mây một cách an toàn.
2. **Cứu hộ và can thiệp State:** Xử lý sự cố kẹt khóa (`force-unlock`), đổi tên tài nguyên trong code mà không làm gián đoạn máy chủ (`state mv`), và gỡ tài nguyên ra khỏi state mà không xóa trên Cloud (`state rm`).
3. **Hiện đại hóa hạ tầng (Import):** Đưa các tài nguyên được tạo thủ công ngoài luồng vào Terraform bằng cả 2 phương pháp: lệnh `terraform import` truyền thống và khối khai báo `import {}` hiện đại của Terraform 1.5+.

---

## 3. Mục Tiêu Học Tập

Sau khi hoàn thành bài lab này, bạn có khả năng:
* **Chuyển đổi** trạng thái lưu trữ hạ tầng từ file state cục bộ (`local state`) sang bộ lưu trữ tập trung (`Remote Backend` như AWS S3) kết hợp cơ chế khóa trạng thái (`State Locking`) với DynamoDB để đảm bảo an toàn dữ liệu khi vận hành nhóm.
* **Xử lý và khắc phục** sự cố lệch trạng thái hạ tầng (`State Drift / Corruption`) bằng các lệnh can thiệp state nâng cao của Terraform CLI (`terraform state mv`, `terraform state rm`, `terraform force-unlock`).
* **Đưa tài nguyên cloud đã tồn tại thực tế** (khởi tạo thủ công) vào luồng quản lý mã nguồn IaC bằng cả lệnh `terraform import` truyền thống và khối khai báo `import {}` (từ Terraform 1.5+).
* **Kiểm tra và xác minh** tính đồng bộ tuyệt đối giữa mã nguồn Terraform, file `tfstate` trên Remote Storage và hạ tầng thực tế trên Cloud.
