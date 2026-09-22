# Chúc Mừng Bạn Đã Hoàn Thành Lab 2!

Bạn đã hoàn thành kịch bản triển khai **Nginx Reverse Proxy & Load Balancing** – một trong những mô hình kiến trúc phổ biến nhất trong hệ thống Microservices, Docker Swarm và Kubernetes Ingress Controller.

---

## Bảng Tóm Tắt Chỉ Thị Nginx Cốt Lõi

| Chỉ Thị | Vị Trí Cấu Hình | Mục Đích Sử Dụng |
|---|---|---|
| `upstream <name> { ... }` | `http` block | Định nghĩa nhóm các máy chủ backend để cân bằng tải |
| `proxy_pass <url>` | `location` block | Chuyển tiếp request đến backend hoặc upstream tương ứng |
| `proxy_set_header Host $host` | `location` block | Giữ lại Header Host ban đầu của Client |
| `proxy_set_header X-Real-IP $remote_addr` | `location` block | Truyền IP gốc của Client cho backend xử lý log/security |
| `proxy_set_header X-Forwarded-For ...` | `location` block | Bổ sung chuỗi IP proxy theo chuẩn RFC 7239 |
| `nginx -t` | Shell command | Kiểm tra cú pháp cấu hình Nginx trước khi áp dụng |
| `nginx -s reload` | Shell command | Nạp lại cấu hình Zero-Downtime không ngắt kết nối client |

---

## Các Thuật Toán Cân Bằng Tải Của Nginx

1. **Round-Robin (Mặc định)**: Phân phối tuần tự lần lượt tới các server theo thứ tự.
2. **Weighted Round-Robin**: Phân phối dựa trên trọng số phần cứng (`weight=X`).
3. **Least Connections (`least_conn;`)**: Gửi request tới server đang có ít kết nối hoạt động nhất (phù hợp với tác vụ xử lý mất nhiều thời gian).
4. **IP Hash (`ip_hash;`)**: Tính hash từ địa chỉ IP của Client để luôn định tuyến cùng một người dùng vào cùng một server backend (hỗ trợ duy trì Session/Stateful).

---

## Tổng Kết Hành Trình 2 Bài Lab DevOps Networking

Qua 2 bài thực hành này, bạn đã trang bị được những kiến thức nền tảng quan trọng:
1. **Lab 1**: Làm chủ mô hình TCP/IP, thành thạo tính toán Subnet CIDR và phân tích cơ chế phân giải DNS phân cấp bằng `dig`.
2. **Lab 2**: Làm chủ kỹ thuật điều phối lưu lượng với Nginx Reverse Proxy, cấu hình Header bảo toàn danh tính Client và cân bằng tải Microservices.

Hãy tiếp tục áp dụng các kiến thức này vào việc thiết kế Docker Compose, Kubernetes Ingress và Cloud VPC!
