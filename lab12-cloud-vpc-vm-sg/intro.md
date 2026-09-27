# Lab 12: VPC · EC2 · Security Groups

## Bối cảnh

Công ty bạn chuyển hệ thống lên Cloud. Nhiệm vụ: xây dựng hạ tầng mạng nền tảng trước khi triển khai bất kỳ dịch vụ nào.

---

## LocalStack — "AWS giả" chạy trên máy bạn

Từ lab này, bạn sẽ dùng **AWS CLI** để ra lệnh cho Cloud. Tuy nhiên, thay vì kết nối vào AWS thật (cần tài khoản, cần thẻ tín dụng, có thể phát sinh chi phí), chúng ta dùng **LocalStack** — một tool chạy ngay trong Docker, mô phỏng lại toàn bộ AWS API.

```
Lab 1-11 (Docker, Git, Networking...)
         │
         ▼
    Docker container
    ─────────────────────────────────────────────
    │  LocalStack                               │
    │  (giả lập AWS API tại localhost:4566)     │
    │  • EC2, VPC, Security Groups              │
    │  • ALB, Auto Scaling                      │
    │  • Budgets, Cost Tags                     │
    ─────────────────────────────────────────────
         │ AWS CLI trỏ vào đây
         ▼
    $ aws ec2 create-vpc ...   ← lệnh giống hệt AWS thật
```

**Kết quả**: bạn gõ đúng lệnh AWS như người dùng AWS thật, nhưng không tốn một đồng nào.

> **Khi nào dùng AWS thật?** Sau khi nắm vững các lệnh trong lab này, bạn chỉ cần thay `--endpoint-url=http://localhost:4566` thành endpoint của AWS thật là toàn bộ lệnh chạy được ngay.

---

## Kiến trúc bài lab

```
            Internet
               │
        ┌──────▼──────┐
        │   Internet  │
        │   Gateway   │
        └──────┬──────┘
               │
    ┌──────────▼──────────┐
    │    VPC 10.0.0.0/16  │
    │  ┌──────────────┐   │
    │  │ Subnet public│   │
    │  │ 10.0.1.0/24  │   │
    │  │  ┌─────────┐ │   │
    │  │  │   EC2   │ │   │
    │  │  │ SG: 22✅│ │   │
    │  │  │     80✅│ │   │
    │  │  └─────────┘ │   │
    │  └──────────────┘   │
    └─────────────────────┘
```

## Mục tiêu

- Tạo VPC, Subnet public, Internet Gateway, Route Table
- Cấu hình Security Group theo nguyên tắc Least Privilege
- Triển khai EC2 instance và kết nối SSH

## Công cụ

| Công cụ | Vai trò |
|---------|---------|
| AWS CLI | Giao tiếp với Cloud API qua terminal |
| LocalStack | Mô phỏng AWS miễn phí, chạy trong Docker |
| Docker | Chạy container đóng vai EC2 instance (web server thật) |
