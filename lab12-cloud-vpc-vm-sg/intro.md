# Lab: Thực hành xây dựng hạ tầng mạng VPC, triển khai máy ảo và cấu hình Security Groups

## Bối cảnh

Công ty bạn đang chuyển đổi hệ thống web application từ On-premises lên Cloud. Bạn được giao nhiệm vụ **xây dựng hạ tầng mạng nền tảng** — bước đầu tiên và quan trọng nhất trước khi triển khai bất kỳ dịch vụ nào lên Cloud.

## Kiến trúc cần xây dựng

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │  Internet   │
                    │  Gateway    │
                    └──────┬──────┘
                           │
          ┌────────────────▼──────────────────┐
          │           VPC: 10.0.0.0/16         │
          │                                    │
          │   ┌────────────────────────────┐   │
          │   │   Subnet Public            │   │
          │   │   10.0.1.0/24              │   │
          │   │                            │   │
          │   │  ┌──────────────────────┐  │   │
          │   │  │  EC2 Instance        │  │   │
          │   │  │  Security Group:     │  │   │
          │   │  │  ✅ Port 22 (SSH)    │  │   │
          │   │  │  ✅ Port 80 (HTTP)   │  │   │
          │   │  │  ❌ Tất cả port khác │  │   │
          │   │  └──────────────────────┘  │   │
          │   └────────────────────────────┘   │
          └────────────────────────────────────┘
```

## Mục tiêu học tập

Sau khi hoàn thành lab này, bạn có thể:

- ✅ Tạo và cấu hình **VPC** với CIDR block theo yêu cầu
- ✅ Thiết lập **Subnet public** và **Internet Gateway** cho phép traffic ra ngoài
- ✅ Cấu hình **Route Table** định tuyến traffic đúng hướng
- ✅ Tạo **Security Group** với quy tắc kiểm soát inbound/outbound
- ✅ Triển khai **EC2 instance** và kết nối SSH vào máy ảo
- ✅ Kiểm thử toàn bộ luồng kết nối từ Internet đến instance

## Công cụ sử dụng

| Công cụ | Vai trò |
|---------|---------|
| **AWS CLI** | Giao tiếp với Cloud API qua terminal |
| **LocalStack** | Mô phỏng AWS tại local (miễn phí, không cần tài khoản) |
| **Docker** | Chạy container đóng vai "EC2 instance" thật |

> 💡 **Lưu ý**: Trong lab này, `aws` đã được cấu hình alias tự động trỏ đến LocalStack.
> Các lệnh bạn gõ **giống hệt** khi làm việc với AWS thật — chỉ khác là không tốn phí.

## Kiểm tra môi trường trước khi bắt đầu

```bash
lab-status
```

Đảm bảo tất cả dịch vụ đều hiển thị ✅ trước khi tiếp tục.
