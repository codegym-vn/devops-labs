# Chúc Mừng Bạn Đã Hoàn Thành Lab 1!

Bạn đã xuất sắc vượt qua cả 3 tầng cốt lõi của mô hình **TCP/IP: Network $\rightarrow$ Transport $\rightarrow$ Application (DNS)** – nền tảng mạng then chốt của mọi hệ thống phân tán, containerization và hạ tầng DevOps.

---

## Bảng Tra Cứu Lệnh Nhanh (DevOps Networking Cheat Sheet)

| Tầng Mạng | Mục Đích | Lệnh Thực Hiện | Ý Nghĩa Kỹ Thuật |
|---|---|---|---|
| **Network** | **Tính toán Subnet/CIDR** | `ipcalc <CIDR>` | Tính Network, Broadcast, dải IP khả dụng, Netmask |
| **Network** | **Xem IP & Card mạng** | `ip -brief address show` | Xem nhanh IP v4/v6 và trạng thái UP/DOWN của interface |
| **Network** | **Xem Default Gateway** | `ip route show` | Xác định gateway ra Internet và card mạng định tuyến |
| **Transport** | **Quét listening sockets** | `ss -tulpn` | Xem danh sách cổng TCP/UDP đang mở cùng tiến trình sở hữu |
| **Transport** | **Test mở Port TCP** | `nc -zv <IP> <Port>` | Kiểm tra kết nối TCP nhanh chóng không cần gửi payload |
| **Transport** | **Xem bắt tay TCP** | `curl -v <URL>` | Theo dõi chi tiết bước kết nối TCP trước khi gửi HTTP |
| **Application**| **Phân giải DNS cơ bản** | `dig <domain> +short` | Trả về trực tiếp IP đích nhanh chóng cho script |
| **Application**| **Kiểm tra loại Record** | `dig <domain> <TYPE> +short` | Kiểm tra các bản ghi: `A`, `CNAME`, `MX`, `TXT`, `NS` |
| **Application**| **Kiểm tra chéo DNS Server**| `dig @8.8.8.8 <domain>` | Truy vấn trực tiếp một DNS Server cụ thể qua cổng 53 |
| **Application**| **Theo dõi đường đi DNS** | `dig <domain> +trace` | Đi từ Root Server -> TLD Server -> Authoritative Server |
| **Application**| **Ghi đè DNS cục bộ** | `/etc/hosts` | Mapping thủ công `<IP> <domain>` ưu tiên hơn DNS ngoài |
| **Application**| **Cấu hình DNS client** | `/etc/resolv.conf` | Định nghĩa nameserver (stub resolver `127.0.0.53`) |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Có thể tính nhẩm và kiểm tra số IP khả dụng cho các dải CIDR phổ biến (`/16`, `/24`, `/27`, `/28`).
- [x] Hiểu tại sao subnet luôn bị mất 2 địa chỉ IP (hoặc 5 IP trong AWS VPC).
- [x] Đọc hiểu bảng định tuyến `ip route` và phân biệt được `default via gateway`.
- [x] Hiểu rõ sự khác biệt giữa TCP vs UDP và quy trình bắt tay 3 bước (SYN $\rightarrow$ SYN-ACK $\rightarrow$ ACK).
- [x] Thành thạo lệnh `ss -tulpn` để điều tra tiến trình nào đang chiếm dụng cổng mạng.
- [x] Sử dụng `nc -zv` để phân biệt sự cố nghẽn mạng do cổng bị đóng/tường lửa chặn hay do ứng dụng lỗi.
- [x] Nắm rõ quy trình 5 bước phân giải một tên miền từ client đến Authoritative Name Server.
- [x] Biết cách dùng `dig` với các tùy chọn `+short`, `+trace`, và `@server` để chẩn đoán lỗi mạng.

---

## Bước Tiếp Theo: Lab 2

Bây giờ bạn đã có nền tảng vững chắc về địa chỉ IP, cổng kết nối TCP và tên miền DNS, hãy chuyển sang **Lab 2: Nginx Reverse Proxy & Load Balancing** để học cách điều phối traffic người dùng vào các dịch vụ backend microservices!
