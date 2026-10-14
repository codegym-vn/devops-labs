# Lab 47: Tối Ưu Hóa Hạ Tầng & Hệ Điều Hành

Chào mừng bạn đến với bài thực hành chuyên sâu về **Tối Ưu Hóa Hạ Tầng & Hệ Điều Hành (Infrastructure & Runtime Tuning)**!

Trong các hệ thống phân tán và kiến trúc Microservices hiện đại, ứng dụng hiếm khi tiếp nhận trực tiếp kết nối từ Internet mà luôn đứng sau một lớp **Reverse Proxy / Load Balancer** (như Nginx, HAProxy, Envoy hoặc Kubernetes Ingress Controller).

Ngay cả khi mã nguồn ứng dụng đã được tối ưu hóa tối đa (đã có Cache-Aside, xử lý mất vài mili-giây), hệ thống vẫn có thể bị sập hoặc nghẽn kết nối khi lưu lượng tăng cao nếu các cấu hình mặc định của hệ điều hành Linux và Web Server không được tinh chỉnh phù hợp.

---

### Hiểm Họa Từ Cấu Hình Mặc Định: "Socket Churn" & Bão Hòa Kết Nối

Khi Nginx chuyển tiếp request tới backend upstream theo cấu hình mặc định:

```mermaid
flowchart TD
    subgraph NonKeepAlive ["Cấu Hình Mặc Định (Không có KeepAlive Upstream)"]
        direction TB
        REQ1["Request 1"] -->|TCP 3-Way Handshake<br/>(SYN -> SYN-ACK -> ACK)| CONN1["Mở Socket Mới"]
        CONN1 --> SEND1["Gửi Request & Nhận Data"]
        SEND1 -->|TCP 4-Way Teardown<br/>(FIN -> ACK)| CLOSE1["Đóng Socket -> Rơi vào TIME_WAIT"]

        REQ2["Request 2"] -->|Lặp lại Handshake mới| CONN2["Mở Socket Mới Khác"]
    end
```

* **Vấn đề 1 (Lãng phí tài nguyên CPU & Mạng):** Mỗi một request HTTP tới Nginx lại buộc hệ điều hành phải thực hiện bắt tay 3 bước (TCP Handshake) và đóng kết nối 4 bước (TCP Teardown) với backend.
* **Vấn đề 2 (Cạn kiệt cổng cục bộ - Port Exhaustion):** Hàng chục nghìn socket rơi vào trạng thái `TIME_WAIT` (duy trì 60 giây theo chuẩn TCP), dẫn đến hết cổng kết nối và Nginx bắt đầu trả về lỗi `502 Bad Gateway` hoặc `Connection refused`.
* **Vấn đề 3 (Giới hạn Worker Connections):** Nếu Nginx chỉ được cấu hình `worker_connections 64` hoặc `256`, khi có hơn 64 kết nối đồng thời, Nginx sẽ từ chối ngay lập tức các kết nối mới.

---

### Giải Pháp: HTTP KeepAlive Upstream Pool & Tinh Chỉnh Linux Kernel

```mermaid
flowchart LR
    NGINX["Nginx Reverse Proxy"] <-->|Duy trì Pool các kết nối TCP mở sẵn<br/>(keepalive 64; proxy_http_version 1.1;)| BACKEND["Upstream Service Backend"]
```

Khi kích hoạt **HTTP KeepAlive Upstream Pool**:
1. Nginx mở sẵn một số lượng kết nối TCP cố định tới backend và giữ chúng luôn mở.
2. Hàng nghìn request liên tiếp sẽ tái sử dụng lại các kết nối có sẵn này (Multiplexing/Persistent Connection) mà không cần tạo mới.
3. Độ trễ giảm đáng kể và hiện tượng cạn kiệt cổng được loại bỏ 100%.

Kết hợp với việc tinh chỉnh các tham số hạt nhân Linux Kernel:
- `net.core.somaxconn`: Mở rộng hàng đợi kết nối đang chờ (Listen Backlog) từ 128 lên 4096.
- `net.ipv4.tcp_max_syn_backlog`: Tăng khả năng tiếp nhận gói tin SYN ban đầu.
- `net.ipv4.ip_local_port_range`: Mở rộng dải cổng từ 32768-60999 thành 10240-65535.

Nhấn **Start** để bước vào quy trình tinh chỉnh hạ tầng thực chiến!
