# Chúc Mừng Bạn Đã Hoàn Thành Lab 3!

Bạn đã triển khai thành công **3 lớp bảo mật** cho server Linux: gia cố SSH, thiết lập đường hầm mã hóa, và cấu hình tường lửa — nền tảng bảo mật thiết yếu cho mọi hạ tầng DevOps.

---

## Bảng Tra Cứu Lệnh Nhanh (SSH & Firewall Cheat Sheet)

### SSH Hardening & Key Management

| Mục Đích | Lệnh | Ý Nghĩa |
|---|---|---|
| **Tạo SSH key Ed25519** | `ssh-keygen -t ed25519 -f <path> -N ""` | Tạo cặp khóa an toàn, tốc độ cao |
| **Copy public key** | `ssh-copy-id -i <key.pub> user@host` | Thêm key vào authorized_keys trên remote |
| **Đăng nhập bằng key** | `ssh -i <private_key> -p <port> user@host` | Kết nối SSH với key cụ thể |
| **Kiểm tra cú pháp sshd** | `sshd -t` | Kiểm tra lỗi cấu hình trước khi restart |
| **Restart SSH** | `systemctl restart ssh` | Áp dụng cấu hình mới |

### SSH Port Forwarding

| Loại | Lệnh | Use Case |
|---|---|---|
| **Local Forwarding** | `ssh -L 9090:host:8080 -N -f user@server` | Truy cập dịch vụ nội bộ từ laptop |
| **Remote Forwarding** | `ssh -R 3000:localhost:3000 -N -f user@server` | Expose dev server ra Internet |
| **Dynamic/SOCKS** | `ssh -D 1080 -N -f user@server` | Proxy mã hóa toàn bộ traffic |

### UFW Firewall

| Mục Đích | Lệnh | Ghi Chú |
|---|---|---|
| **Xem trạng thái** | `ufw status verbose` | Rules và chính sách mặc định |
| **Bật tường lửa** | `ufw --force enable` | Kích hoạt (thêm rule SSH trước!) |
| **Cho phép cổng** | `ufw allow <port>/tcp` | Mở cổng TCP cụ thể |
| **Chặn cổng** | `ufw deny <port>/tcp` | Đóng cổng cụ thể |
| **Rate limit** | `ufw limit <port>/tcp` | Chống brute-force (6 lần/30s) |
| **Cho phép từ subnet** | `ufw allow from <CIDR> to any port <port>` | Giới hạn theo dải IP |
| **Xóa rule** | `ufw delete <number>` | Xóa rule theo số thứ tự |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Tạo được SSH Key Pair Ed25519 và hiểu sự khác biệt với RSA.
- [x] Cấu hình `sshd_config` với các chỉ thị hardening: đổi port, tắt password, giới hạn thử sai.
- [x] Hiểu nguyên tắc hoạt động của SSH Local Port Forwarding (`-L`).
- [x] Phân biệt được 3 loại SSH Tunnel: Local (`-L`), Remote (`-R`), Dynamic/SOCKS (`-D`).
- [x] Biết cách thiết lập chính sách mặc định UFW: deny incoming, allow outgoing.
- [x] Thêm được rules UFW cho phép/chặn cổng cụ thể.
- [x] Áp dụng rate limiting trên UFW để chống brute-force SSH.
- [x] Cấu hình UFW cho phép truy cập từ dải IP cụ thể (ví dụ: database chỉ cho mạng nội bộ).
- [x] Hiểu tầm quan trọng của việc thêm rule SSH **trước khi** bật UFW trên server production.

---

## Quy Trình Hardening Server Cho Production

Khi nhận một server Linux mới, hãy thực hiện theo thứ tự:

1. **Cập nhật hệ thống**: `apt update && apt upgrade -y`
2. **Tạo user thường** (không dùng root trực tiếp): `adduser devops && usermod -aG sudo devops`
3. **Cài đặt SSH key** cho user mới: `ssh-copy-id devops@server`
4. **Gia cố sshd_config**: Đổi port, tắt password, cấm root login.
5. **Bật UFW**: Cho phép SSH trước, sau đó bật firewall.
6. **Cài đặt fail2ban** (nâng cao): Tự động chặn IP brute-force bằng iptables.
7. **Cấu hình automatic security updates**: `apt install unattended-upgrades`

---

## Bước Tiếp Theo

Bây giờ bạn đã nắm vững cách bảo mật truy cập server, tạo đường hầm mã hóa và kiểm soát traffic mạng. Hãy chuyển sang **Lab 4: Nginx Reverse Proxy, Load Balancer & Connection Pooling** để học cách điều phối traffic người dùng vào cụm backend và tối ưu hiệu năng kết nối!

