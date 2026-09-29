# Bước 3: Kết Nối Đa Tầng Liên Container & Kiểm Thử Cô Lập Mạng

Trong bước này, bạn sẽ kết hợp toàn bộ kiến thức đã học để xây dựng mô hình **Kiến trúc đa tầng (Multi-tier Application)**: một dịch vụ cơ sở dữ liệu/bộ nhớ đệm (**Redis**) chạy có **Named Volume**, được bảo vệ an toàn trên **Custom Bridge Network**, và một dịch vụ **Web Client** kết nối nội bộ qua tên miền. Đồng thời, bạn sẽ kiểm chứng nguyên tắc **Cô lập mạng (Network Isolation)**.

---

## 1. Lý Thuyết: Ứng Dụng Đa Tầng & Bảo Mật Mạng Container

Trong thiết kế hạ tầng Production, các dịch vụ lưu trữ dữ liệu (PostgreSQL, MySQL, Redis) **tuyệt đối không bao giờ được mở cổng trực tiếp ra ngoài Internet** (không dùng `-p 6379:6379` nếu không cần thiết). Thay vào đó:

1. Dịch vụ Database/Cache chỉ lắng nghe bên trong mạng riêng ảo (`app-net`).
2. Các dịch vụ Backend hoặc Web Client cùng nằm trong mạng `app-net` sẽ giao tiếp với Database qua tên container (`redis-db`).
3. Dữ liệu của Database được bảo toàn lâu dài qua Named Volume (`redis_data`).
4. Các container bên ngoài (nằm ở mạng mặc định hoặc mạng khác) hoàn toàn bị cô lập và không thể quét hoặc truy cập trái phép vào Database.

```
                    Mạng Riêng Biệt (app-net: 172.28.0.0/16)
       ┌─────────────────────────────────────────────────────────────────┐
       │                                                                 │
       │   ┌───────────────────────────┐     ┌───────────────────────┐   │
       │   │ Container: web-client     │     │ Container: redis-db   │   │
       │   │                           │────►│ (Port 6379 nội bộ)    │   │
       │   │ Gửi lệnh: SET/GET         │     │                       │   │
       │   └───────────────────────────┘     └───────────┬───────────┘   │
       │                                                 │               │
       └─────────────────────────────────────────────────┼───────────────┘
                                                         │
                                             Mount: -v redis_data:/data
                                                         │
                                                         ▼
                                            ┌─────────────────────────┐
    Mạng Khác (Default Bridge)              │ Named Volume: redis_data│
       ┌───────────────────────────┐        └─────────────────────────┘
       │ Container: isolated-box   │
       │                           │
       │ Lệnh ping redis-db ───────┼─ ❌ Bị chặn (Network Isolation)
       └───────────────────────────┘
```

---

## 2. Thực Hành

### 3.1 — Tạo Named Volume cho Database (`redis_data`)

Khởi tạo volume lưu trữ dữ liệu bền vững cho cụm Redis:

```bash
docker volume create redis_data
```{{exec}}

---

### 3.2 — Triển khai Tầng Cơ Sở Dữ Liệu (`redis-db`)

Khởi chạy container Redis, gắn volume `redis_data` vào thư mục `/data` và kết nối trực tiếp vào mạng `app-net`:

```bash
docker run -d --name redis-db \
  --network app-net \
  -v redis_data:/data \
  redis:7-alpine redis-server --appendonly yes
```{{exec}}

Kiểm tra trạng thái container đang hoạt động:

```bash
docker ps --filter "name=redis-db"
```{{exec}}

---

### 3.3 — Triển khai Tầng Web Client (`web-client`)

Khởi chạy container client trên cùng mạng `app-net`:

```bash
docker run -d --name web-client \
  --network app-net \
  alpine:3.19 \
  sleep 3600
```{{exec}}

---

### 3.4 — Kết nối Liên Container qua Tên Miền

Cài đặt công cụ `redis-cli` vào `web-client` và thực hiện gửi lệnh truy vấn tới `redis-db` bằng Container Name:

```bash
docker exec web-client apk add --no-cache redis
```{{exec}}

Kiểm tra phản hồi PING/PONG từ máy chủ Redis:

```bash
docker exec web-client redis-cli -h redis-db PING
```{{exec}}

Ghi và đọc dữ liệu mẫu qua mạng:

```bash
docker exec web-client redis-cli -h redis-db SET learner_role "DevOps Engineer"
docker exec web-client redis-cli -h redis-db GET learner_role
```{{exec}}

Bạn nhận được kết quả `"DevOps Engineer"`. Hai container đã giao tiếp mượt mà qua mạng riêng biệt mà không hề cần mở cổng ra máy host!

---

### 3.5 — Kiểm thử Tính Cô Lập Mạng (Network Isolation)

Khởi chạy một container độc lập `isolated-box` nằm trên mạng mặc định (`default bridge`):

```bash
docker run -d --name isolated-box alpine:3.19 sleep 3600
```{{exec}}

Thử phân giải tên miền hoặc ping sang `redis-db`:

```bash
docker exec isolated-box ping -c 1 -W 2 redis-db
```{{exec}}

Kết quả trả về thông báo lỗi: `ping: bad address 'redis-db'`. Container ngoài mạng hoàn toàn không thể chạm tới máy chủ Redis bên trong mạng `app-net`.

---

### 3.6 — Gắn Kết Nối Nóng Vào Mạng (Docker Network Connect)

Trong thực tế vận hành, khi cần cấp quyền cho một dịch vụ tham gia vào mạng đang hoạt động mà không cần khởi động lại container:

```bash
docker network connect app-net isolated-box
```{{exec}}

Thử ping lại từ `isolated-box` sang `redis-db`:

```bash
docker exec isolated-box ping -c 1 -W 2 redis-db
```{{exec}}

Lúc này, kết nối đã thành công!

---

## 3. Hoàn Thành & Xác Minh

Nhấn nút **Check** ở góc dưới bên trái để hệ thống tự động kiểm tra:
1. Volume `redis_data` đã được tạo thành công.
2. Container `redis-db` đang chạy trên mạng `app-net` và gắn volume `redis_data`.
3. Container `web-client` đang chạy trên mạng `app-net`.
4. Giá trị key `learner_role` trong Redis có giá trị `"DevOps Engineer"`.
5. Container `isolated-box` được tạo và kiểm thử kết nối thành công.
