# Lab 25: Thực Hành Quét Lỗ Hổng Bảo Mật Mã Nguồn Terraform Với Checkov & Tfsec

Trong triết lý **DevSecOps**, nguyên tắc quan trọng nhất là **Shift-Left Security** — chuyển dịch các hoạt động kiểm tra an ninh về càng sớm càng tốt trong chu trình phát triển phần mềm, thay vì đợi đến khi hạ tầng đã triển khai lên Cloud mới quét lỗ hổng.

Hạ tầng dạng mã nguồn (Infrastructure as Code - IaC) với Terraform định nghĩa toàn bộ mạng, máy chủ, cơ sở dữ liệu và phân quyền. Một sai sót nhỏ trong tệp cấu hình `.tf` (chẳng hạn vô tình mở cổng SSH 22 ra Internet, hoặc để lộ S3 Bucket chứa dữ liệu tài chính không mã hóa) có thể biến toàn bộ hệ thống đám mây thành mục tiêu tấn công tức thì.

---

## 1. So Sánh Hai Công Cụ Quét IaC Hàng Đầu

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MÃ NGUỒN TERRAFORM (*.tf)                          │
└──────────────────────┬───────────────────────────────┬──────────────────────┘
                       │                               │
                       ▼                               ▼
       ┌───────────────────────────────┐┌───────────────────────────────┐
       │             TFSEC             ││            CHECKOV            │
       │  (Aqua Security / Go Binary)  ││ (Bridgecrew / Python Scanner) │
       ├───────────────────────────────┤├───────────────────────────────┤
       │ • Tốc độ quét cực nhanh (ms)  ││ • Quét đa dạng: IaC, K8s, CI  │
       │ • Chuyên biệt cho Terraform   ││ • Hàng trăm luật chuẩn CIS    │
       │ • Rất nhẹ, dễ dùng trên CLI   ││ • Báo cáo chuyên sâu, SARIF   │
       └───────────────────────────────┘└───────────────────────────────┘
```

* **Tfsec:** Công cụ siêu nhẹ viết bằng Go, chuyên dụng để lập trình viên quét nhanh ngay trên máy cá nhân trước khi commit.
* **Checkov:** Công cụ kiểm thử an ninh tĩnh toàn diện của Bridgecrew, áp dụng các tiêu chuẩn an ninh quốc tế (CIS Benchmarks, NIST, HIPAA), lý tưởng để làm Cổng kiểm soát chất lượng (Quality Gate) trong pipeline CI/CD.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

* Sử dụng `tfsec` quét nhanh và bóc tách các cảnh báo an ninh hạ tầng.
* Chạy `checkov` phân tích sâu các vi phạm chuẩn CIS và xuất báo cáo.
* Khắc phục triệt để các cấu hình sai lệch trên S3 Bucket và Security Group.
* Áp dụng kỹ thuật bỏ qua có giải trình (Suppression) đúng quy chuẩn doanh nghiệp.

Nhấn **Next** để bắt đầu bước đầu tiên!
