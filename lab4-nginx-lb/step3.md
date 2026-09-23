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

## 2. Bật Connection Pooling Với `keepalive`

Chỉ thị `keepalive` trong upstream block cho phép Nginx **giữ sẵn một pool kết nối mở** tới backend, tái sử dụng cho các request tiếp theo:

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;

    # Duy tri toi da 32 idle connections trong pool
    keepalive 32;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;

        # BAT BUOC khi dung keepalive upstream
        proxy_http_version 1.1;          # HTTP/1.1 ho tro persistent connection
        proxy_set_header Connection "";  # Xoa header "Connection: close"

        # Bao toan thong tin client
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```{{exec}}

```bash
nginx -s reload
```{{exec}}

### Giải thích cấu hình bắt buộc

| Chỉ Thị | Tại Sao Bắt Buộc |
|---|---|
| `keepalive 32` | Số lượng idle connections tối đa trong pool. Khi cần kết nối mới, Nginx lấy từ pool thay vì tạo TCP mới |
| `proxy_http_version 1.1` | HTTP/1.0 mặc định đóng kết nối sau mỗi response. HTTP/1.1 hỗ trợ persistent connection |
| `proxy_set_header Connection ""` | Xóa header `Connection: close` mà client gửi, ngăn nó lan tới backend và đóng kết nối |

> **Lưu ý quan trọng:** `keepalive 32` không phải là **tổng số kết nối tối đa** mà là số **idle connections** (kết nối rảnh) được giữ trong pool. Nginx vẫn có thể mở thêm kết nối nếu cần. Nếu pool đầy, kết nối cũ nhất sẽ bị đóng.

---

## 3. Kiểm Tra Connection Pooling Hoạt Động

Gửi nhiều request và kiểm tra kết nối:

```bash
for i in $(seq 1 20); do curl -s http://localhost > /dev/null; done
```{{exec}}

Kiểm tra kết nối TCP tới backend:

```bash
ss -tn | grep -E "800[1-3]" | head -10
```{{exec}}

Với keepalive, bạn sẽ thấy các kết nối ở trạng thái `ESTAB` (established) **vẫn tồn tại** sau khi request hoàn thành — đây là pool connections đang chờ tái sử dụng.

---

## 4. Các Tham Số Tuning Quan Trọng

### Bảng tham số keepalive

| Tham Số | Vị Trí | Mặc Định | Khuyến Nghị | Ý Nghĩa |
|---|---|---|---|---|
| `keepalive` | upstream | (tắt) | 32–64 | Số idle connections trong pool |
| `keepalive_requests` | upstream | 1000 | 1000–10000 | Số request tối đa trên 1 connection trước khi đóng và tạo mới |
| `keepalive_timeout` | upstream | 60s | 60–120s | Thời gian giữ idle connection trước khi đóng |

### Bảng tham số proxy timeout

| Tham Số | Vị Trí | Mặc Định | Khuyến Nghị | Ý Nghĩa |
|---|---|---|---|---|
| `proxy_connect_timeout` | server/location | 60s | 5–10s | Timeout kết nối TCP tới backend |
| `proxy_read_timeout` | server/location | 60s | 30–60s | Timeout chờ response từ backend |
| `proxy_send_timeout` | server/location | 60s | 30–60s | Timeout gửi request body tới backend |

### Thêm tham số tuning vào cấu hình

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;

    keepalive 32;
    keepalive_requests 1000;
    keepalive_timeout 60s;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;

        # Keepalive bat buoc
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Timeout tuning
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;

        # Bao toan thong tin client
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```{{exec}}

```bash
nginx -t && nginx -s reload
```{{exec}}

Kiểm tra Nginx vẫn hoạt động:

```bash
curl http://localhost
```{{exec}}

---

## 5. Tổng Kết Cấu Hình Hoàn Chỉnh

Sau 3 bước, bạn đã xây dựng cấu hình Nginx hoàn chỉnh:

```text
┌───────────────────────────────────────────────────────┐
│                    Nginx (Port 80)                     │
├───────────────────────────────────────────────────────┤
│  ✓ Reverse Proxy    : proxy_pass → upstream           │
│  ✓ Client Headers   : X-Real-IP, X-Forwarded-For     │
│  ✓ Load Balancing   : Round Robin / Weighted / LC     │
│  ✓ Connection Pool  : keepalive 32, HTTP/1.1          │
│  ✓ Timeout Tuning   : connect 5s, read 30s            │
├───────────────────────────────────────────────────────┤
│                    upstream pool                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐     │
│  │ Backend 8001│ │ Backend 8002│ │ Backend 8003│     │
│  └─────────────┘ └─────────────┘ └─────────────┘     │
└───────────────────────────────────────────────────────┘
```

---

## 6. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo Connection Pooling đã được cấu hình đúng:

1. Upstream block có chỉ thị `keepalive`.
2. Location block có `proxy_http_version 1.1`.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
