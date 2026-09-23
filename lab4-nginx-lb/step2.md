# Bước 2: Load Balancing - Upstream & Thuật Toán Phân Phối Traffic

Ở Bước 1, Nginx chỉ chuyển tiếp tới **một backend duy nhất** (8001). Trong production, bạn cần phân phối request qua **nhiều backend** để tăng khả năng chịu tải (scalability) và tính sẵn sàng cao (high availability). Nginx thực hiện điều này qua **upstream block**.

---

## 1. Upstream Block — Nhóm Backend

`upstream` là chỉ thị của Nginx để định nghĩa một nhóm backend server:

```text
  Trước (1 backend):                  Sau (3 backend + upstream):

  location / {                        upstream backend_pool {
      proxy_pass http://127.0.0.1:8001;       server 127.0.0.1:8001;
  }                                           server 127.0.0.1:8002;
                                              server 127.0.0.1:8003;
                                      }
                                      location / {
                                          proxy_pass http://backend_pool;
                                      }
```

### Cấu hình Load Balancing cơ bản (Round Robin)

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```{{exec}}

Reload Nginx:

```bash
nginx -s reload
```{{exec}}

### Kiểm tra Round Robin

Gửi 6 request liên tiếp và quan sát response luân phiên qua 3 backend:

```bash
for i in $(seq 1 6); do
    echo "Request $i: $(curl -s http://localhost)"
done
```{{exec}}

Kết quả sẽ luân phiên: Backend 8001 → 8002 → 8003 → 8001 → 8002 → 8003. Đây là thuật toán **Round Robin** — mặc định của Nginx, phân phối đều request cho từng backend theo thứ tự.

---

## 2. Các Thuật Toán Load Balancing

### Bảng tổng hợp

| Thuật Toán | Directive | Cách Hoạt Động | Use Case |
|---|---|---|---|
| **Round Robin** | (mặc định) | Lần lượt từng backend theo thứ tự | Các backend đồng đều về cấu hình |
| **Weighted Round Robin** | `weight=N` | Backend weight cao nhận nhiều request hơn | Backend mạnh/yếu khác nhau |
| **Least Connections** | `least_conn` | Ưu tiên backend đang ít kết nối nhất | Request xử lý lâu, thời gian không đồng đều |
| **IP Hash** | `ip_hash` | Cùng IP client luôn tới cùng backend | Session sticky, giỏ hàng, đăng nhập |

---

### Weighted Round Robin — Phân phối theo trọng số

Khi các backend có cấu hình phần cứng khác nhau (ví dụ: server 8001 mạnh gấp 3 lần), dùng `weight` để phân phối tỷ lệ:

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001 weight=3;   # Nhan 60% request (3/5)
    server 127.0.0.1:8002 weight=1;   # Nhan 20% request (1/5)
    server 127.0.0.1:8003 weight=1;   # Nhan 20% request (1/5)
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;
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

Gửi 10 request và đếm phân phối:

```bash
for i in $(seq 1 10); do curl -s http://localhost; done | sort | uniq -c | sort -rn
```{{exec}}

Backend 8001 nhận khoảng 6/10 request, 8002 và 8003 mỗi backend khoảng 2/10.

---

### Least Connections — Ưu tiên backend ít tải nhất

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    least_conn;                        # Uu tien backend dang it ket noi nhat
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;
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

> **Khi nào dùng Least Connections?** Khi thời gian xử lý request không đồng đều (ví dụ: một số API call mất 100ms, một số mất 5 giây). Round Robin sẽ dồn request vào backend đang bận, còn Least Connections sẽ ưu tiên backend rảnh hơn.

---

### IP Hash — Session Sticky

```nginx
upstream backend_pool {
    ip_hash;                           # Cung IP client luon toi cung backend
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}
```

> **Khi nào dùng IP Hash?** Khi ứng dụng backend lưu session trong bộ nhớ (in-memory session). Nếu user bị chuyển sang backend khác giữa phiên, session sẽ bị mất (phải đăng nhập lại). **Lưu ý:** IP Hash không lý tưởng khi nhiều user dùng chung NAT/IP (ví dụ: nhân viên trong cùng công ty) — toàn bộ sẽ dồn vào 1 backend.

---

## 3. Health Check & Backup Server

Nginx tự động kiểm tra sức khỏe backend thông qua `max_fails` và `fail_timeout`:

```nginx
upstream backend_pool {
    server 127.0.0.1:8001 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8002 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8003 backup;      # Chi dung khi cac server chinh deu down
}
```

| Tham Số | Mặc Định | Ý Nghĩa |
|---|---|---|
| `max_fails` | 1 | Số lần request thất bại trước khi đánh dấu backend unhealthy |
| `fail_timeout` | 10s | Thời gian chờ trước khi thử lại backend đã bị đánh dấu lỗi |
| `backup` | - | Server dự phòng, chỉ nhận traffic khi tất cả server chính đều down |
| `down` | - | Đánh dấu server tạm tắt (bảo trì), không nhận traffic |

---

## 4. Thực Hành: Chuyển Về Round Robin Cho Bước 3

Để chuẩn bị cho Bước 3 (Connection Pooling), hãy chuyển lại về Round Robin cơ bản:

```bash
cat << 'EOF' > /etc/nginx/conf.d/proxy.conf
upstream backend_pool {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    server 127.0.0.1:8003;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://backend_pool;
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

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy đảm bảo Load Balancing đang hoạt động:

1. Upstream block đã được cấu hình với ít nhất 2 backend.
2. Gửi nhiều request, response phải đến từ ít nhất 2 backend khác nhau.

Bấm nút **Check** bên dưới thanh điều khiển để hệ thống tự động xác thực!
