# Bước 3: Connection Pooling - Keepalive & Performance Tuning

Ở Bước 1 và 2, mỗi khi Nginx chuyển tiếp request tới backend, nó mở một **kết nối TCP mới**, xử lý xong rồi **đóng kết nối ngay**. Trong hệ thống xử lý hàng nghìn request/giây, việc liên tục mở/đóng kết nối tạo ra chi phí lớn (TCP handshake, TIME_WAIT state). **Connection Pooling** giải quyết vấn đề này bằng cách **tái sử dụng kết nối** đã có.

---

## 1. Vấn Đề: Không Có Connection Pooling

```text
  Không có keepalive:                     Có keepalive:

  Request 1: [TCP Open] → [Send] → [Close]    Request 1: [TCP Open] → [Send]
  Request 2: [TCP Open] → [Send] → [Close]    Request 2:              [Send]  (tái sử dụng)
  Request 3: [TCP Open] → [Send] → [Close]    Request 3:              [Send]  (tái sử dụng)
  ...                                          ...
  (Mỗi request tạo kết nối mới)              (Chỉ tạo 1 lần, dùng lại nhiều lần)
```

**Chi phí của việc tạo kết nối mới mỗi lần:**
- **TCP 3-Way Handshake**: Tốn ít nhất 1 RTT (Round Trip Time) trước khi gửi được data.
- **TIME_WAIT state**: Sau khi đóng kết nối, port bị giữ trong trạng thái TIME_WAIT 60 giây. Nếu traffic cao, cạn kiệt port khả dụng.
- **CPU overhead**: Kernel phải xử lý tạo/hủy socket cho mỗi request.

### Xem trạng thái kết nối hiện tại

```bash
ss -tn state established | head -20
```{{exec}}

---

## 2. Nguyên Lý & Các Chỉ Thị Bắt Buộc Của Connection Pooling

Chỉ thị `keepalive` trong upstream block cho phép Nginx **giữ sẵn một pool kết nối mở** tới backend, tái sử dụng cho các request tiếp theo thay vì đóng mở liên tục.

Để Connection Pooling hoạt động chính xác giữa Nginx và backend, bạn **bắt buộc phải phối hợp cả 3 chỉ thị sau**:

### 1. `keepalive <N>` (trong khối `upstream`)
Khai báo số lượng kết nối rảnh (idle connections) tối đa được lưu trữ trong connection pool cho mỗi worker process:
```nginx
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;

    keepalive 32;   # Duy tri toi da 32 idle connections trong pool
}
```

> **Lưu ý quan trọng:** `keepalive 32` không phải là tổng số kết nối tối đa Nginx có thể mở tới backend, mà là số kết nối nhàn rỗi (idle) được giữ lại sau khi xử lý xong request. Nếu pool đầy, kết nối cũ nhất sẽ bị đóng.

### 2. `proxy_http_version 1.1;` (trong khối `location`)
Mặc định Nginx proxy sử dụng **HTTP/1.0** khi nói chuyện với backend. Giao thức HTTP/1.0 không hỗ trợ keepalive (mặc định đóng kết nối sau mỗi response). Vì vậy bắt buộc phải chuyển sang **HTTP/1.1**.

### 3. `proxy_set_header Connection "";` (trong khối `location`)
Theo mặc định, nếu client gửi header `Connection: close`, Nginx sẽ chuyển tiếp header này tới backend khiến backend đóng kết nối ngay lập tức. Việc xóa rỗng header này (`Connection ""`) giúp backend hiểu rằng kết nối cần được giữ mở.

| Chỉ Thị | Vị Trí | Ý Nghĩa Bắt Buộc |
|---|---|---|
| `keepalive 32` | `upstream` | Kích hoạt pool lưu trữ idle connections |
| `proxy_http_version 1.1` | `location` | Chuyển giao thức proxy sang HTTP/1.1 hỗ trợ persistent connection |
| `proxy_set_header Connection ""` | `location` | Xóa cờ đóng kết nối từ client, giữ kết nối tái sử dụng |

---

## 3. Các Tham Số Tuning Bổ Sung Trong Production

### Tham số tối ưu Keepalive (khối `upstream`):

| Tham Số | Mặc Định | Khuyến Nghị | Ý Nghĩa |
|---|---|---|---|
| `keepalive_requests` | 1000 | 1000–10000 | Số request tối đa gửi qua 1 kết nối trước khi đóng và tạo mới |
| `keepalive_timeout` | 60s | 60–120s | Thời gian tối đa một kết nối idle được lưu trong pool |

### Tham số tối ưu Timeout (khối `location`):

| Tham Số | Mặc Định | Khuyến Nghị | Ý Nghĩa |
|---|---|---|---|
| `proxy_connect_timeout` | 60s | 5–10s | Thời gian chờ kết nối TCP tới backend server |
| `proxy_read_timeout` | 60s | 30–60s | Thời gian chờ backend xử lý và trả dữ liệu |
| `proxy_send_timeout` | 60s | 30–60s | Thời gian chờ gửi dữ liệu (request body) lên backend |

---

## 4. Thử Thách & Cấu Hình Thực Hành (Hands-on DIY)

Hãy tự tay áp dụng các chỉ thị Connection Pooling và Tuning vào file cấu hình `/etc/nginx/conf.d/proxy.conf`:

### Yêu cầu thử thách:
1. Trong khối `upstream backend_pool`:
   - Thêm `keepalive 32;`
   - Thêm `keepalive_timeout 60s;`
2. Trong khối `location /`:
   - Kích hoạt `proxy_http_version 1.1;`
   - Xóa header kết nối: `proxy_set_header Connection "";`
   - Thêm timeout kết nối: `proxy_connect_timeout 5s;`
   - Thêm timeout đọc dữ liệu: `proxy_read_timeout 30s;`
   - Vẫn bảo toàn đầy đủ headers: `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`.
3. Kiểm tra cú pháp bằng lệnh `nginx -t` và reload lại dịch vụ: `nginx -s reload`.
4. Tự kiểm tra kết quả bằng cách gửi 20 request liên tiếp:
   ```bash
   for i in $(seq 1 20); do curl -s http://localhost > /dev/null; done
   ```
   Sau đó quan sát danh sách socket kết nối tới backend:
   ```bash
   ss -tn | grep -E "800[1-3]"
   ```
   Bạn sẽ thấy các kết nối ở trạng thái `ESTAB` (established) vẫn tồn tại trong pool thay vì chuyển sang `TIME_WAIT`!

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý file cấu hình hoàn chỉnh</summary>

Mở file cấu hình bằng trình soạn thảo:
```bash
nano /etc/nginx/conf.d/proxy.conf
```

Hoặc ghi đè nội dung cấu hình chuẩn:
```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;

    keepalive 32;
    keepalive_timeout 60s;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;

        # Connection Pooling bat buoc
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Timeout tuning
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;

        # Bao toan thong tin client
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

Sau đó kiểm tra và reload:
```bash
nginx -t && nginx -s reload
```

</details>

---

## 5. Tổng Kết Kiến Trúc Hoàn Chỉnh

Sau cả 3 bước thực hành, bạn đã xây dựng thành công kiến trúc Reverse Proxy & Load Balancer chuẩn production:

```text
┌───────────────────────────────────────────────────────────────┐
│                        Nginx (Port 80)                        │
├───────────────────────────────────────────────────────────────┤
│  ✓ Reverse Proxy    : proxy_pass http://backend_pool          │
│  ✓ Client Headers   : X-Real-IP, X-Forwarded-For, Host, Proto │
│  ✓ Load Balancing   : Round Robin / Weighted / Least Conn     │
│  ✓ Connection Pool  : keepalive 32, HTTP/1.1, Connection ""   │
│  ✓ Timeout Tuning   : connect 5s, read 30s                    │
├───────────────────────────────────────────────────────────────┤
│                     upstream backend_pool                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │  Backend 8001   │ │  Backend 8002   │ │  Backend 8003   │  │
│  │ (Python Server) │ │ (Python Server) │ │ (Python Server) │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

---

## 6. Xác Thực Hệ Thống (Verification)

Hãy đảm bảo Nginx đã được nạp cấu hình mới nhất và các backend phản hồi bình thường.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực toàn bộ cấu hình Connection Pooling!
