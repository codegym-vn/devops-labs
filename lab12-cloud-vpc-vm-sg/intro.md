# Lab 12: VPC · EC2 · Security Groups

## Bối cảnh

Công ty bạn chuyển hệ thống lên Cloud. Nhiệm vụ: xây dựng hạ tầng mạng nền tảng trước khi triển khai bất kỳ dịch vụ nào.

## Kiến trúc

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
| AWS CLI | Gọi Cloud API qua terminal |
| LocalStack | Mô phỏng AWS miễn phí, không cần tài khoản |
| Docker | Chạy container đóng vai EC2 instance |
