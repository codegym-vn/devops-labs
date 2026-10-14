# Bước 3: Tinh Chỉnh Nginx KeepAlive & Tham Số Hạt Nhân Linux (sysctl)

Để khắc phục triệt để hiện tượng bão hòa kết nối và lỗi `64 worker_connections are not enough`, bạn sẽ tiến hành tối ưu hóa đồng thời cả hai tầng: **Hệ điều hành Linux Kernel** và **Nginx Reverse Proxy**.

---

### 1. Tinh Chỉnh Các Tham Số Mạng Của Linux Kernel

Tạo tệp cấu hình tham số hạt nhân tại `/root/infra-opt-lab/sysctl/99-tuning.conf`:

```bash
cat << 'EOF' > /root/infra-opt-lab/sysctl/99-tuning.conf
# 1. Mo rong do dai hang doi lang nghe ket noi (Listen Backlog)
net.core.somaxconn = 4096

# 2. Tang hang doi tiep nhan goi tin SYN ban dau
net.ipv4.tcp_max_syn_backlog = 4096

# 3. Mo rong dai cong cuc bo de chong can kiet port khi tai cao
net.ipv4.ip_local_port_range = 10240 65535
EOF
```

Nạp các tham số mới vào kernel:

```bash
sysctl -p /root/infra-opt-lab/sysctl/99-tuning.conf 2>/dev/null || true
```

---

### 2. Tinh Chỉnh Cấu Hình Nginx (Worker Connections & KeepAlive Pool)

Ghi đè cấu hình tối ưu vào tệp `/root/infra-opt-lab/nginx/nginx.conf`:

```bash
cat << 'EOF' > /root/infra-opt-lab/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    # Tang gioi han tu 64 len 4096 ket noi dong thoi tren moi worker
    worker_connections 4096;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream backend_nodes {
        server 127.0.0.1:8080;

        # Kich hoat HTTP KeepAlive Pool: giu toi da 64 ket noi TCP mo san
        keepalive 64;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://backend_nodes;

            # Bat buoc phai dung HTTP 1.1 va xoa header Connection de tai su dung socket
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
        }
    }
}
EOF
```

*Điểm cốt lõi cần ghi nhớ:*
* `keepalive 64;`: Nginx duy trì sẵn một hồ bơi gồm 64 kết nối TCP tới backend. Khi có request mới đến, Nginx sử dụng ngay kết nối có sẵn thay vì tốn thời gian bắt tay TCP 3 bước.
* `proxy_http_version 1.1;` & `proxy_set_header Connection "";`: Hai chỉ thị bắt buộc để Nginx giao tiếp với upstream theo chuẩn KeepAlive thay vì HTTP/1.0 Connection: Close mặc định.

---

### 3. Nạp Lại Cấu Hình Nginx (Hot-Reload)

Sử dụng lệnh `nginx-reload` để kiểm tra cú pháp và nạp lại cấu hình mà không làm gián đoạn dịch vụ:

```bash
nginx-reload
```

*Đảm bảo terminal in ra thông báo:*
```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Da nạp lại cấu hình Nginx thành công.
```

Kiểm tra lại kết nối:
```bash
curl -s http://localhost:80/api/data | jq .
```

Sau khi Nginx đã nạp cấu hình mới thành công, nhấn **Check** để hoàn thành Bước 3!
