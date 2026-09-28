# Lab 12: Xây Dựng Hạ Tầng Mạng Cloud với AWS CLI & LocalStack

Chào mừng bạn đến với bài thực hành hạ tầng mạng Cloud chuyên sâu. Trong bài lab này, bạn sẽ sử dụng trực tiếp **AWS CLI (Command Line Interface)** để xây dựng một kiến trúc mạng an toàn chuẩn doanh nghiệp trên nền tảng giả lập **LocalStack**.

---

## 1. Kiến Trúc Hạ Tầng Cần Xây Dựng

Bạn sẽ thiết kế và triển khai một hệ thống mạng cô lập nhiều tầng (Multi-tier Architecture):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS Virtual Private Cloud (VPC): 10.0.0.0/16 (devops-vpc)                  │
│                                                                             │
│  ┌─────────────────────────────────┐   ┌─────────────────────────────────┐  │
│  │ Public Subnet: 10.0.1.0/24      │   │ Private Subnet: 10.0.2.0/24     │  │
│  │ (public-subnet)                 │   │ (private-subnet)                │  │
│  │                                 │   │                                 │  │
│  │   ┌─────────────────────────┐   │   │   ┌─────────────────────────┐   │  │
│  │   │ EC2: web-server-1       │   │   │   │ EC2: db-server-1        │   │  │
│  │   │ IP: 10.0.1.x            │   │   │   │ IP: 10.0.2.x            │   │  │
│  │   │                         │   │   │   │                         │   │  │
│  │   │ Security Group (web-sg):│   │   │   │ Security Group (db-sg): │   │  │
│  │   │ • Inbound: 80 (HTTP)    │   │   │   │ • Inbound: 5432 (DB)    │   │  │
│  │   │ • Inbound: 22 (SSH)     │   │   │   │   CHỈ TỪ web-sg!        │   │  │
│  │   └────────────▲────────────┘   │   │   └────────────▲────────────┘   │  │
│  └────────────────┼────────────────┘   └────────────────┼────────────────┘  │
│                   │                                     │                   │
│          Route: 0.0.0.0/0                               │ (Không có IGW)    │
│                   ▼                                     │                   │
│        [ Internet Gateway ]                             │                   │
└───────────────────┼─────────────────────────────────────┴───────────────────┘
                    ▼
          Internet (Users / Client)
```

---

## 2. Giải Mã Công Thức Câu Lệnh AWS CLI

Trong thực tế vận hành DevOps, các kỹ sư ít khi dùng giao diện web (Console) để bấm click chuột vì chậm và khó tự động hóa. Thay vào đó, chúng ta sử dụng **AWS CLI** theo công thức:

```text
aws   <service>   <action>   [--parameters]
 │        │           │             │
 │        │           │             └── Tham số cấu hình (--cidr-block, --region...)
 │        │           └──────────────── Hành động muốn thực hiện (create-vpc, run-instances...)
 │        └──────────────────────────── Dịch vụ cần thao tác (ec2, s3, elbv2...)
 └───────────────────────────────────── Lệnh gọi công cụ AWS CLI
```

* **Ví dụ 1:** Tạo một mạng VPC mới:
  ```bash
  aws ec2 create-vpc --cidr-block 10.0.0.0/16
  ```
* **Ví dụ 2:** Liệt kê các máy ảo EC2 đang chạy:
  ```bash
  aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
  ```

> [!NOTE]
> **Về Môi Trường LocalStack:**  
> Hệ thống lab đã tích hợp sẵn **LocalStack** trên cổng `4566`. Lệnh `aws` trong terminal của bạn đã được cấu hình tự động trỏ vào LocalStack (`endpoint-url http://localhost:4566`), giúp bạn thực hành các câu lệnh chuẩn của AWS mà **hoàn toàn miễn phí, an toàn và không cần nhập thẻ tín dụng**.

---

## 3. Mục Tiêu Bạn Cần Đạt Được

1. **Bước 1:** Dùng AWS CLI tạo VPC (`10.0.0.0/16`), Public Subnet, Private Subnet, Internet Gateway và bảng định tuyến Route Table.
2. **Bước 2:** Tạo các Security Group (`web-sg`, `db-sg`) và cấu hình cơ chế liên kết bảo mật (Chaining Security Groups) theo chuẩn DevSecOps Least Privilege.
3. **Bước 3:** Khởi tạo SSH Key Pair và triển khai các máy ảo EC2 vào đúng Subnet quy định.
4. **Bước 4:** Kiểm thử toàn bộ kiến trúc, phân tích trạng thái tài nguyên và thực hành quy trình dọn dẹp (Cleanup) theo thứ tự phụ thuộc.
