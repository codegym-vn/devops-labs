# Bước 1: Triển Khai Nginx Reverse Proxy & Load Balancing

Trong kịch bản này, bạn sẽ từng bước thiết lập một hệ thống hoàn chỉnh: dựng 2 backend microservices giả lập, cấu hình Nginx làm cổng tiếp nhận (Reverse Proxy), và thiết lập cân bằng tải (Load Balancing).

---

## 1. Cài Đặt Nginx và Công Cụ Hỗ Trợ

Cập nhật danh sách gói và cài đặt Nginx cùng Python 3:

```bash
apt-get update && apt-get install -y nginx curl python3
```{{exec}}

Kiểm tra trạng thái Nginx đã chạy hay chưa:

```bash
systemctl status nginx --no-pager
```{{exec}}

Kiểm tra trang mặc định của Nginx trên cổng 80:

```bash
curl -I http://localhost
```{{exec}}

---

## 2. Khởi Tạo 2 Dịch Vụ Backend Giả Lập

Chúng ta sẽ sử dụng script Python đơn giản để khởi chạy 2 HTTP servers giả lập 2 microservices:
- **Backend 1**: Chạy trên cổng `8081`
- **Backend 2**: Chạy trên cổng `8082`

Tạo thư mục làm việc và file script server:

```bash
mkdir -p /opt/backends
cat << 'EOF' > /opt/backends/server.py
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

port = int(sys.argv[1])
app_id = sys.argv[2]

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain; charset=utf-8')
        self.end_headers()
        client_ip = self.headers.get('X-Real-IP', self.client_address[0])
        response = f"[{app_id}] Trả lời từ cổng {port} | Client Real IP: {client_ip}\n"
        self.wfile.write(response.encode('utf-8'))
        print(f"[{app_id}] Handled request from {self.client_address[0]} (X-Real-IP: {client_ip})")

    def log_message(self, format, *args):
        return # Giảm bớt log mặc định

server = HTTPServer(('127.0.0.1', port), SimpleHandler)
print(f"Backend {app_id} đang lắng nghe tại 127.0.0.1:{port}...")
server.serve_forever()
EOF
```{{exec}}

Khởi chạy 2 backend ngầm trong nền:

```bash
python3 /opt/backends/server.py 8081 "Backend-1" > /tmp/backend1.log 2>&1 &
python3 /opt/backends/server.py 8082 "Backend-2" > /tmp/backend2.log 2>&1 &
```{{exec}}

Kiểm tra trực tiếp kết nối tới từng backend:

```bash
curl http://localhost:8081
curl http://localhost:8082
```{{exec}}

---

## 3. Cấu Hình Nginx Làm Reverse Proxy (1-to-1)

Mục tiêu: Khi người dùng gọi tới cổng 80 (`http://localhost/`), Nginx sẽ chuyển tiếp (proxy) yêu cầu đến `http://127.0.0.1:8081`.

Xóa cấu hình mặc định cũ để tránh xung đột cổng 80:

```bash
rm -f /etc/nginx/sites-enabled/default
```{{exec}}

Tạo file cấu hình reverse proxy mới tại `/etc/nginx/conf.d/app.conf`:

```bash
cat << 'EOF' > /etc/nginx/conf.d/app.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8081;

        # Chuyển tiếp các HTTP Headers quan trọng
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```{{exec}}

### Giải thích các chỉ thị quan trọng:
- `proxy_pass`: URL của dịch vụ backend mà Nginx sẽ chuyển tiếp gói tin tới.
- `proxy_set_header Host $host`: Giữ nguyên tên miền gốc mà client yêu cầu (rất quan trọng cho Virtual Hosting).
- `proxy_set_header X-Real-IP $remote_addr`: Gán địa chỉ IP thực của Client vào header. Nếu không có dòng này, backend sẽ chỉ thấy IP của Nginx (`127.0.0.1`).
- `proxy_set_header X-Forwarded-For`: Danh sách chuỗi IP mà request đã đi qua.

Kiểm tra cú pháp cấu hình Nginx (luôn thực hiện trước khi reload):

```bash
nginx -t
```{{exec}}

Nạp lại cấu hình Nginx mà không làm gián đoạn kết nối (Zero-Downtime Reload):

```bash
nginx -s reload
```{{exec}}

Kiểm tra thử bằng cách gọi vào cổng 80:

```bash
curl http://localhost
```{{exec}}

Bạn sẽ thấy phản hồi đến từ `[Backend-1] Trả lời từ cổng 8081`!

---

## 4. Nâng Cấp Lên Cân Bằng Tải (Load Balancing)

Bây giờ hệ thống phát triển, lượng truy cập tăng gấp đôi. Ta cần phân phối tải đều giữa **Backend-1** và **Backend-2**.

Cập nhật lại file cấu hình `/etc/nginx/conf.d/app.conf` để bổ sung khối `upstream`:

```bash
cat << 'EOF' > /etc/nginx/conf.d/app.conf
upstream backend_cluster {
    # Thuật toán mặc định: Round-Robin (Luân phiên)
    server 127.0.0.1:8081 weight=1;
    server 127.0.0.1:8082 weight=1;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend_cluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Cấu hình timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
    }
}
EOF
```{{exec}}

Kiểm tra cú pháp và nạp lại cấu hình:

```bash
nginx -t && nginx -s reload
```{{exec}}

---

## 5. Kiểm Thử Cân Bằng Tải Round-Robin

Gửi 6 requests liên tục đến Nginx cổng 80 để quan sát thuật toán Round-Robin hoạt động:

```bash
for i in {1..6}; do curl -s http://localhost; done
```{{exec}}

**Kết quả quan sát được:**
```text
[Backend-1] Trả lời từ cổng 8081 | Client Real IP: 127.0.0.1
[Backend-2] Trả lời từ cổng 8082 | Client Real IP: 127.0.0.1
[Backend-1] Trả lời từ cổng 8081 | Client Real IP: 127.0.0.1
[Backend-2] Trả lời từ cổng 8082 | Client Real IP: 127.0.0.1
[Backend-1] Trả lời từ cổng 8081 | Client Real IP: 127.0.0.1
[Backend-2] Trả lời từ cổng 8082 | Client Real IP: 127.0.0.1
```
Traffic đã được chia đều 50/50 luân phiên chính xác giữa 2 cụm máy chủ!

---

## 6. Mở Rộng: Phân Tải Theo Trọng Số (Weighted Load Balancing)

Nếu Backend-2 là máy chủ cấu hình mạnh gấp 3 lần Backend-1, bạn có thể chỉnh:
```nginx
upstream backend_cluster {
    server 127.0.0.1:8081 weight=1;
    server 127.0.0.1:8082 weight=3;
}
```
Khi đó cứ 4 requests thì Backend-2 sẽ nhận 3 requests, Backend-1 chỉ nhận 1 request.

Bấm **Next** để xem phần tổng kết và các kinh nghiệm vận hành Nginx trong Production!
