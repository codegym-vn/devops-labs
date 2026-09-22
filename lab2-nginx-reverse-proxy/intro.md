# Lab 2: Nginx Reverse Proxy & Load Balancing Trong DevOps

Chào mừng bạn đến với bài lab **Nginx Reverse Proxy & Load Balancing**.

Trong các kiến trúc hệ thống hiện đại, người dùng bên ngoài Internet hầu như **không bao giờ kết nối trực tiếp** vào các máy chủ ứng dụng (Application Servers) hay cơ sở dữ liệu. Thay vào đó, toàn bộ traffic đi qua một lớp trung gian đóng vai trò "người gác cổng" – đó chính là **Reverse Proxy** và **Load Balancer**.

---

## Reverse Proxy Khác Gì Forward Proxy?

| Đặc Điểm | Forward Proxy (Ủy Quyền Chiều Đi) | Reverse Proxy (Ủy Quyền Chiều Về) |
|---|---|---|
| **Vị trí** | Đặt trước Client (người dùng nội bộ) | Đặt trước Backend Servers |
| **Mục đích** | Bảo vệ/ẩn danh Client, kiểm soát truy cập web công ty | Bảo vệ Backend, phân phối tải, SSL Termination |
| **Ví dụ** | Proxy Squid, VPN, Corporate Internet Gateway | **Nginx**, HAProxy, Traefik, AWS ALB |
| **Người biết đích đến** | Client chủ động cấu hình gửi qua Proxy | Client nghĩ rằng Proxy chính là Server đích |

---

## Kiến Trúc Hệ Thống Trong Bài Lab Này

```text
               HTTP Request (:80)
   Client  ─────────────────────────►  [ Nginx Reverse Proxy ]
 (Trình duyệt)                             │          │
                                   Round   │          │  Robin
                                  Robin   │          │
                                          ▼          ▼
                                   [ Backend 1 ]  [ Backend 2 ]
                                    (Port 8081)    (Port 8082)
```

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài lab này, bạn sẽ:
1. **Triển khai và kiểm tra hoạt động của Nginx** trên môi trường Linux Ubuntu.
2. **Khởi tạo các dịch vụ backend mẫu** chạy ngầm để mô phỏng cụm Microservices.
3. **Cấu hình chỉ thị `proxy_pass`** để chuyển tiếp yêu cầu HTTP từ port 80 vào backend.
4. **Bảo toàn IP thực của Client** bằng cách thiết lập các HTTP Header quan trọng (`X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, `Host`).
5. **Cấu hình Load Balancing với khối `upstream`** theo thuật toán Round-Robin và kiểm thử việc phân phối tải giữa các backend node.

Bấm **START** để bắt đầu cài đặt và cấu hình!
