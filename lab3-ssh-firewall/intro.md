Chào mừng bạn đến với bài lab **SSH Hardening, Port Forwarding & Tường Lửa UFW**.

Trong vận hành hệ thống DevOps, **SSH** (Secure Shell) là cánh cửa chính để truy cập và quản lý server Linux từ xa. Đồng thời, **Tường lửa (Firewall)** là hàng rào kiểm soát toàn bộ traffic mạng vào/ra server. Nếu SSH bị tấn công hoặc Firewall không được cấu hình đúng, kẻ xâm nhập có thể chiếm quyền điều khiển toàn bộ hạ tầng.

---

## Các Mối Đe Dọa Phổ Biến

- **Brute-Force Attack**: Bot tự động quét port 22 và thử hàng nghìn tổ hợp username/password mỗi phút.
- **Unauthorized Access**: Cho phép đăng nhập root bằng password là rủi ro lớn nhất trên server production.
- **Lateral Movement**: Sau khi chiếm được một server, kẻ tấn công sẽ lợi dụng kết nối mạng nội bộ để lan sang các server khác.

---

## Ba Lớp Bảo Mật Trong Bài Lab

| Lớp | Công Nghệ | Mục Tiêu | Bước |
|---|---|---|---|
| **Lớp 1: Xác thực** | SSH Hardening | Kiểm soát ai được phép đăng nhập và bằng cách nào | **Bước 1** |
| **Lớp 2: Kết nối** | SSH Port Forwarding | Tạo đường hầm mã hóa để truy cập dịch vụ nội bộ an toàn | **Bước 2** |
| **Lớp 3: Mạng** | UFW Firewall | Kiểm soát traffic nào được phép đi vào/ra server | **Bước 3** |

---

## Kiến Trúc Bảo Mật Tổng Quan

```text
                              Lớp 3: UFW Firewall
                         ┌──────────────────────────┐
    Internet             │   Cho phép: 2222, 80, 443│
    (Bot, Hacker,  ──────│   Chặn: 23 (Telnet)      │
     Người dùng)         │   Rate Limit: SSH         │
                         └───────────┬──────────────┘
                                     │
                              Lớp 1: SSH Hardening
                         ┌───────────┴──────────────┐
                         │   Port 2222 (không phải 22)│
                         │   Key-based Auth Only      │
                         │   No Root Login             │
                         └───────────┬──────────────┘
                                     │
                              Lớp 2: SSH Tunnel
                         ┌───────────┴──────────────┐
                         │   Local Forwarding (-L)    │
                         │   Remote Forwarding (-R)   │
                         │   Dynamic SOCKS (-D)       │
                         └──────────────────────────┘
```

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, bạn sẽ:
1. **Tạo SSH Key Pair (Ed25519)** và cấu hình xác thực bằng khóa công khai thay vì password.
2. **Gia cố sshd_config** với các chỉ thị bảo mật: cấm root login, đổi port, giới hạn số lần thử.
3. **Thiết lập SSH Local Port Forwarding** để truy cập dịch vụ nội bộ qua đường hầm mã hóa.
4. **Hiểu các loại SSH Tunnel**: Local (`-L`), Remote (`-R`), Dynamic/SOCKS (`-D`).
5. **Cấu hình tường lửa UFW**: cho phép/chặn cổng, rate limiting chống brute-force.
6. **Áp dụng quy trình hardening server** chuẩn cho môi trường production.

---

## Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường (Background Initialization)**: `openssh-server`, `ufw`, `netcat` được hệ thống tự động cài đặt ngầm.
- **Thực thi lệnh nhanh**: Bấm trực tiếp vào các khối lệnh code trên hướng dẫn để tự động chạy trên terminal.
- **Xác thực tự động (Verify Check)**: Mỗi bước đều có phần **Thử Thách**. Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động chấm điểm.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu!
