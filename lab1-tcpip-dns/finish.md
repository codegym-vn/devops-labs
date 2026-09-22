# Chúc Mừng Bạn Đã Hoàn Thành Lab 1!

Bạn đã xuất sắc vượt qua các nội dung cốt lõi về **TCP/IP, Subnetting & DNS** – nền tảng mạng then chốt của mọi hệ thống phân tán và hạ tầng DevOps.

---

## Bảng Tra Cứu Lệnh Nhanh (DevOps Networking Cheat Sheet)

| Mục Đích | Lệnh Thực Hiện | Ý Nghĩa Kỹ Thuật |
|---|---|---|
| **Tính toán Subnet/CIDR** | `ipcalc <CIDR>` | Tính Network, Broadcast, dải IP khả dụng, Netmask |
| **Xem IP & Card mạng** | `ip -brief address show` | Xem nhanh IP v4/v6 và trạng thái UP/DOWN của card mạng |
| **Xem Default Gateway** | `ip route show` | Xác định cổng ra Internet và card mạng định tuyến |
| **Phân giải DNS cơ bản** | `dig <domain> +short` | Trả về trực tiếp IP đích nhanh chóng cho script |
| **Kiểm tra loại Record** | `dig <domain> <TYPE> +short` | Kiểm tra các bản ghi: `A`, `CNAME`, `MX`, `TXT`, `NS` |
| **Kiểm tra chéo DNS Server** | `dig @8.8.8.8 <domain>` | Truy vấn trực tiếp một DNS Server cụ thể qua cổng 53 |
| **Theo dõi đường đi DNS** | `dig <domain> +trace` | Đi từ Root Server $\rightarrow$ TLD Server $\rightarrow$ Authoritative Server |
| **Ghi đè DNS cục bộ** | `/etc/hosts` | Mapping thủ công `<IP> <domain>` ưu tiên hơn DNS ngoài |
| **Cấu hình DNS client** | `/etc/resolv.conf` | Định nghĩa nameserver và search domain cho máy/container |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Có thể tính nhẩm và kiểm tra số IP khả dụng cho các dải CIDR phổ biến (`/16`, `/24`, `/27`, `/28`).
- [x] Hiểu tại sao subnet luôn bị mất 2 địa chỉ IP (hoặc 5 IP trong AWS VPC).
- [x] Đọc hiểu bảng định tuyến `ip route` và phân biệt được `default via gateway`.
- [x] Nắm rõ quy trình 5 bước phân giải một tên miền từ client đến Authoritative Name Server.
- [x] Biết cách dùng `dig` với các tùy chọn `+short`, `+trace`, và `@server` để chẩn đoán lỗi mạng.

---

## Bước Tiếp Theo: Lab 2

Bây giờ bạn đã có nền tảng vững chắc về địa chỉ IP và tên miền, hãy chuyển sang **Lab 2: Nginx Reverse Proxy & Load Balancing** để học cách điều phối traffic người dùng vào các dịch vụ backend microservices!
