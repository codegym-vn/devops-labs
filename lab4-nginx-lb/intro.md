Chào mừng bạn đến với bài lab **Nginx Reverse Proxy, Load Balancer & Connection Pooling**.

Trong kiến trúc microservices hiện đại, người dùng **không bao giờ** truy cập trực tiếp vào backend application. Thay vào đó, mọi request đều đi qua một tầng **Reverse Proxy** (thường là Nginx hoặc HAProxy) — nơi thực hiện phân phối traffic, bảo mật, SSL termination và tối ưu hiệu năng kết nối. Đây là kiến thức cốt lõi để vận hành bất kỳ hệ thống production nào.

---

## Tại Sao DevOps Engineer Cần Nắm Vững Reverse Proxy & Load Balancing?

- **Zero-Downtime Deployment**: Khi deploy phiên bản mới, Nginx chuyển hướng traffic sang backend mới mà người dùng không bị gián đoạn.
- **Horizontal Scaling**: Thêm backend server mới vào upstream pool mà không cần thay đổi cấu hình client.
- **High Availability**: Nếu một backend bị crash, Nginx tự động loại bỏ và chuyển traffic sang backend còn sống.
- **Performance**: Connection Pooling giảm chi phí tạo kết nối TCP mới, tăng throughput tổng thể.

---

## So Sánh: Truy Cập Trực Tiếp vs Qua Reverse Proxy

| Đặc Tính | Truy Cập Trực Tiếp | Qua Reverse Proxy (Nginx) |
|---|---|---|
| **Client biết IP backend** | Có — lộ IP nội bộ | Không — chỉ thấy IP của Nginx |
| **SSL Certificate** | Mỗi backend tự quản lý | Tập trung tại Nginx (SSL Termination) |
| **Load Balancing** | Không có — client tự chọn server | Nginx phân phối tự động |
| **Health Check** | Client phải tự xử lý | Nginx tự loại backend lỗi |
| **Connection Reuse** | Mỗi request mở TCP mới | Nginx tái sử dụng connection (keepalive) |

---

## Kiến Trúc Tổng Quan Bài Lab

```text
                                         ┌─── Backend 8001 (Python HTTP Server)
                                         │    "Response from Backend 8001"
Client ──── Port 80 ────> [ Nginx ] ─────├─── Backend 8002 (Python HTTP Server)
 (curl)                   Reverse Proxy  │    "Response from Backend 8002"
                          Load Balancer  └─── Backend 8003 (Python HTTP Server)
                          Conn Pool           "Response from Backend 8003"
                             │
                  ┌──────────┼──────────┐
               Bước 1     Bước 2     Bước 3
            Reverse Proxy  Load      Connection
            proxy_pass   Balancing    Pooling
                         upstream    keepalive
```

---

## Mục Tiêu Bài Học

Sau khi hoàn thành bài thực hành này, học viên có khả năng:
1. **Cấu hình** Nginx làm Reverse Proxy chuyển tiếp request tới backend bằng `proxy_pass`.
2. **Thiết lập** HTTP headers (`X-Real-IP`, `X-Forwarded-For`) để bảo toàn thông tin IP client qua proxy.
3. **Triển khai** upstream block với Load Balancing phân phối traffic qua nhiều backend.
4. **Phân biệt** 4 thuật toán Load Balancing: Round Robin, Weighted, Least Connections, IP Hash.
5. **Áp dụng** Connection Pooling (`keepalive`) để tối ưu hiệu năng kết nối giữa Nginx và backend.
6. **Cấu hình** các tham số tuning quan trọng: timeout, buffer, keepalive requests.

---

## Tính Năng Tương Tác Trên Killercoda

- **Tự động hóa môi trường (Background Initialization)**: Nginx và 3 backend giả lập (port 8001, 8002, 8003) được hệ thống tự động cài đặt và khởi chạy ngầm.
- **Thực thi lệnh nhanh**: Bấm trực tiếp vào các khối lệnh code trên hướng dẫn để tự động chạy trên terminal.
- **Xác thực tự động (Verify Check)**: Mỗi bước đều có phần **Thử Thách**. Sau khi hoàn thành, hãy bấm nút **Check** để hệ thống tự động chấm điểm.

Bấm **START** hoặc chọn **Bước 1** để bắt đầu!
