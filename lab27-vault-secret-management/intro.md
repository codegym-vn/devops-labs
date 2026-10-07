# Lab 27: Quản Trị & Inject Secret An Toàn Vào Pipeline Với HashiCorp Vault

Trong các bài học trước, bạn đã hiểu rằng việc để lộ khóa bí mật (Secrets, Passwords, API Keys) trong mã nguồn hoặc tệp cấu hình phẳng (`config.json`, `.env`) là một lỗ hổng an ninh chết người.

Tuy nhiên, câu hỏi đặt ra là: **Làm thế nào để ứng dụng và pipeline CI/CD có thể truy cập được cơ sở dữ liệu hoặc dịch vụ bên thứ ba một cách an toàn mà không bao giờ ghi cứng mật khẩu vào code?**

Giải pháp chuẩn mực của các tập đoàn công nghệ hàng đầu thế giới chính là: **HashiCorp Vault**.

---

## 1. Kiến Trúc Vận Hành Của HashiCorp Vault

```
                               ┌────────────────────────────────┐
                               │     HASHICORP VAULT SERVER     │
                               │  (Mã hóa at-rest & in-transit) │
                               └───────────────┬────────────────┘
                                               │
                         ┌─────────────────────┴─────────────────────┐
                         │ Phân quyền bằng Vault Policy              │
                         ▼                                           ▼
             ┌───────────────────────┐                   ┌───────────────────────┐
             │       ỨNG DỤNG        │                   │    CI/CD PIPELINE     │
             │  (Xác thực AppRole)   │                   │  (Xác thực AppRole)   │
             │                       │                   │                       │
             │ Lấy Secret tại Runtime│                   │ Tự động nạp Secret    │
             │ và lưu trữ trong RAM  │                   │ vào biến môi trường   │
             └───────────────────────┘                   └───────────────────────┘
```

* **Mã hóa tập trung:** Mọi secret đều được mã hóa bằng thuật toán AES-256-GCM trước khi ghi vào bộ lưu trữ.
* **Nguyên tắc Least Privilege:** Thông qua **Vault Policy**, mỗi dịch vụ chỉ có quyền đọc đúng secret của nó, không thể xem secret của dịch vụ khác.
* **Cơ chế AppRole Authentication:** Thay vì dùng tài khoản cá nhân, các hệ thống tự động (CI/CD runner, server, Pod) sử dụng cặp khóa `RoleID` và `SecretID` để đăng nhập và lấy Token tạm thời có hạn dùng (TTL).
* **Audit Trail:** Mọi hành vi đọc, ghi, sửa hoặc xóa secret đều được ghi nhật ký bất biến để phục vụ thanh tra an ninh.

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

* Kiểm tra trạng thái Vault Server và lưu trữ secret vào KV-v2 Secret Engine.
* Viết tệp chính sách **Vault Policy** (HCL) phân quyền đọc hạn chế.
* Kích hoạt và cấu hình phương thức xác thực **AppRole** dành riêng cho hệ thống máy móc.
* Xây dựng kịch bản inject secret từ Vault vào ứng dụng Node.js chạy trong bộ nhớ RAM mà không để lại dấu vết trên ổ đĩa.

Nhấn **Next** để bắt đầu bước đầu tiên!
