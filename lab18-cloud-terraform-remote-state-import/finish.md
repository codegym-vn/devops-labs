# 🏆 Chúc Mừng! Bạn Đã Hoàn Thành Lab 18: Remote Backend & Import Hạ Tầng

Bạn vừa làm chủ thành công những kỹ năng nâng cao nhất trong quản trị vòng đời mã nguồn Terraform: **Bảo vệ State tập trung với S3 + DynamoDB**, **Xử lý sự cố kẹt khóa**, **Tái cấu trúc không downtime với State CLI**, và **Hiện đại hóa hạ tầng có sẵn bằng khối `import {}`**!

---

## 1. Tóm Tắt Toàn Bộ Kỹ Thuật Đạt Được

```text
 1. Remote Backend Chuẩn Enterprise:
    AWS S3 Bucket         ──► Lưu trữ tập trung terraform.tfstate, kích hoạt Versioning & mã hóa
    AWS DynamoDB Table    ──► Khóa trạng thái (State Locking) chống Race Condition khi nhiều người cùng apply
    terraform init -migrate ──► Di chuyển an toàn từ Local State lên Cloud mà không làm gián đoạn hệ thống

 2. Cứu Hộ & Can Thiệp State File:
    terraform force-unlock ──► Giải phóng khóa kẹt khi pipeline CI/CD bị crash đột ngột
    terraform state mv     ──► Đổi tên resource trong code mà KHÔNG gây downtime xóa/tạo lại máy chủ
    terraform state rm     ──► Gỡ tài nguyên ra khỏi State mà vẫn bảo toàn nguyên vẹn trên Cloud

 3. Hiện Đại Hóa Hạ Tầng (Brownfield Adoption):
    terraform import       ──► Nạp tài nguyên tạo thủ công vào State theo cách truyền thống
    Khối import {}         ──► Khai báo ý định import trực tiếp trong code HCL (Terraform 1.5+)
    -generate-config-out   ──► Tự động sinh mã nguồn HCL chuẩn xác 100% từ tài nguyên thực tế
```

---

## 2. Bảng Tra Cứu Lệnh Can Thiệp State & Import (DevOps Cheat Sheet)

| Lệnh | Ý Nghĩa Vận Hành Thực Tế | Tình Huống Áp Dụng |
| :--- | :--- | :--- |
| `terraform init -migrate-state` | Di chuyển state giữa các backend (Local lên S3 hoặc giữa các bucket) | Khi nâng cấp dự án từ cá nhân lên làm việc nhóm |
| `terraform force-unlock <ID>` | Xóa khóa đang bị kẹt trong DynamoDB để mở quyền apply | Khi apply bị đứt mạng hoặc pipeline CI/CD bị ngắt bất ngờ |
| `terraform state list` | Liệt kê tất cả tài nguyên đang được theo dõi trong Remote State | Kiểm tra nhanh các resource đang nằm dưới quyền Terraform |
| `terraform state show <addr>` | Hiển thị toàn bộ thuộc tính chi tiết của một tài nguyên từ S3 | Lấy thông số để viết code HCL khi thực hiện import |
| `terraform state mv <A> <B>` | Di chuyển hoặc đổi tên tài nguyên trong State file | Tái cấu trúc (refactor) tên resource mà không xóa hạ tầng |
| `terraform state rm <addr>` | Xóa tài nguyên khỏi State nhưng KHÔNG xóa trên Cloud | Khi muốn ngừng quản lý tài nguyên bằng Terraform |
| `terraform import <addr> <id>` | Nạp tài nguyên có sẵn trên Cloud vào State hiện tại | Đưa hạ tầng cũ (ClickOps) vào quản lý bằng IaC |
| `terraform plan -generate-config-out=<f>` | Tự động quét Cloud và sinh mã nguồn HCL vào file | Sử dụng kết hợp với khối `import {}` để tạo code tự động |

---

## 3. Câu Hỏi Phỏng Vấn DevOps & Cloud Thường Gặp

1. **State Locking trong Terraform hoạt động như thế nào khi sử dụng AWS S3 làm Remote Backend?**
   * *Trả lời:* Bản thân S3 chỉ là dịch vụ lưu trữ Object nên không hỗ trợ khóa hàng (row-level locking). Terraform giải quyết vấn đề này bằng cách kết hợp với **AWS DynamoDB**. Trước khi thực thi bất kỳ thao tác thay đổi nào (`plan` hoặc `apply`), Terraform tạo một item chứa mã băm `LockID` vào bảng DynamoDB. Nếu có tiến trình khác cố gắng thực thi cùng lúc, DynamoDB sẽ từ chối do khóa đã tồn tại (`ConditionalCheckFailedException`), ngăn chặn triệt để xung đột ghi đè.

2. **Sự khác biệt căn bản giữa lệnh `terraform import` cũ và khối khai báo `import {}` từ Terraform 1.5+ là gì?**
   * *Trả lời:*
     * Lệnh `terraform import` mang tính **mệnh lệnh (Imperative)**: chạy trực tiếp từ CLI, chỉ cập nhật state chứ không sinh code HCL, không thể review qua Pull Request.
     * Khối `import {}` mang tính **khai báo (Declarative)**: được viết trực tiếp vào file `.tf`, có thể commit lên Git để review trong PR, và đặc biệt hỗ trợ cờ `-generate-config-out` giúp Terraform tự động sinh ra mã HCL hoàn chỉnh.

3. **Khi nào thì một kỹ sư DevOps nên sử dụng `terraform state rm` thay vì xóa code và chạy `terraform apply`?**
   * *Trả lời:* Khi bạn muốn chuyển giao quyền sở hữu tài nguyên cho một team khác, tách module độc lập, hoặc chuyển tài nguyên sang quản lý bằng công cụ khác (như Kubernetes Operator hoặc Pulumi) mà **bắt buộc không được làm gián đoạn hay xóa mất dữ liệu của tài nguyên đó trên Cloud**. Nếu bạn chỉ xóa code rồi apply, Terraform sẽ coi đó là ý định muốn tiêu hủy (destroy) tài nguyên!
