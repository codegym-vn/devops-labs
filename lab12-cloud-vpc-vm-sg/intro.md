# Lab 12: Hạ tầng mạng Cloud — VPC, Subnet, Security

## Cloud networking hoạt động thế nào?

Trong Cloud, toàn bộ hạ tầng mạng được **ảo hóa bằng phần mềm**. Bạn không cần cắm dây cáp hay cấu hình switch vật lý — mọi thứ được tạo và xóa bằng lệnh.

Ba khái niệm cốt lõi:

```
┌─────────────────────────────────────────────┐
│  VPC (Virtual Private Cloud)                │
│  Mạng ảo riêng — tách biệt hoàn toàn với   │
│  các khách hàng khác trên cùng datacenter   │
│                                             │
│  ┌──────────────┐   ┌──────────────┐        │
│  │  Subnet A    │   │  Subnet B    │        │
│  │  (Public)    │   │  (Private)   │        │
│  │              │   │              │        │
│  │  [Server 1]  │   │  [Database]  │        │
│  │  SG: 80    │   │  SG: 5432  │        │
│  │      22    │   │      22    │        │
│  └──────────────┘   └──────────────┘        │
└─────────────────────────────────────────────┘
         │
    Internet Gateway
         │
      Internet
```

**Tương đương trong thực tế:**

| Khái niệm Cloud | Dùng trong lab | AWS | GCP | Azure |
|----------------|----------------|-----|-----|-------|
| VPC | Docker network | AWS VPC | VPC Network | Virtual Network |
| Subnet | Docker subnet | Subnet | Subnet | Subnet |
| Security Group | UFW rules | Security Group | Firewall Rules | NSG |
| EC2 Instance | Docker container | EC2 | Compute Engine | Virtual Machine |
| Internet Gateway | Port mapping | IGW | Cloud Router | VNet Gateway |

> Bạn đã dùng Docker networks từ Lab 9-11 và UFW từ Lab 3. Lab này ghép chúng lại theo mô hình Cloud networking.

## Mục tiêu

- Hiểu VPC là mạng ảo tách biệt, Subnet là phân vùng trong VPC
- Tạo và cấu hình Security Group (tường lửa cấp instance)
- Triển khai web server vào VPC và kiểm soát traffic vào/ra
- Mô phỏng kiến trúc Public Subnet vs Private Subnet
