# Bước 2: Triển Khai Redis Exporter Giám Sát Dịch Vụ CSDL

Ở Bước 1, bạn đã thấy Node Exporter đọc trực tiếp thông số từ nhân Linux Kernel (`/proc` và `/sys`).

Trong phần mềm ứng dụng hoặc cơ sở dữ liệu (Database/Cache), các thông số không nằm trong hệ điều hành mà nằm trong bộ nhớ nội bộ của phần mềm đó. Để giám sát Redis, chúng ta sử dụng **Redis Exporter** — exporter này sẽ định kỳ gửi lệnh `INFO` vào Redis, phân tách các trường và định dạng lại thành chuẩn OpenMetrics tại cổng `9121`.

---

### 1. Khởi Chạy Cơ Sở Dữ Liệu Redis Làm Mục Tiêu

Khởi chạy một phiên bản Redis độc lập trên cổng tiêu chuẩn `6379`:

```bash
docker run -d --name redis \
  --network host \
  redis:7-alpine
```

Kiểm tra kết nối Redis bằng công cụ dòng lệnh:

```bash
docker exec -i redis redis-cli ping
```
*(Kết quả trả về `PONG` xác nhận Redis đã sẵn sàng)*.

---

### 2. Triển Khai Redis Exporter

Khởi chạy container **redis-exporter** trỏ đến địa chỉ `127.0.0.1:6379`:

```bash
docker run -d --name redis-exporter \
  --network host \
  oliver006/redis_exporter:v1.58.0 \
  --redis.addr=redis://127.0.0.1:6379
```

Kiểm tra endpoint `/metrics` của Redis Exporter tại cổng `9121`:

```bash
curl -s http://localhost:9121/metrics | grep -E "^redis_up|^redis_connected_clients"
```

Giải thích các chỉ số cốt lõi:
- **`redis_up 1`**: Cho biết Exporter kết nối thông suốt với Redis Server (`1` là bình thường, `0` là mất kết nối).
- **`redis_connected_clients`**: Số lượng phiên kết nối đồng thời vào CSDL.
- **`redis_commands_total`**: Tổng số lệnh nghiệp vụ đã thực thi qua Redis.

---

### 3. Thử Nghiệm Tác Động Dữ Liệu Lên Metrics

Gửi 3 lệnh ghi/đọc dữ liệu vào Redis:

```bash
docker exec -i redis redis-cli set user:101 "Nguyen Van A"
docker exec -i redis redis-cli get user:101
docker exec -i redis redis-cli incr counter:hits
```

Kiểm tra lại chỉ số lệnh đã xử lý:

```bash
curl -s http://localhost:9121/metrics | grep "^redis_commands_processed_total"
```
Bạn sẽ thấy giá trị Counter này tăng lên tương ứng với số lệnh bạn vừa thực thi.

---

### 4. Yêu Cầu Hoàn Thành Bước 2

Trích xuất trạng thái kết nối `redis_up` và số clients lưu vào tệp **/root/prometheus-lab/step2-redis-metrics.txt**:

```bash
curl -s http://localhost:9121/metrics | grep -E "^redis_up|^redis_connected_clients" > /root/prometheus-lab/step2-redis-metrics.txt
cat /root/prometheus-lab/step2-redis-metrics.txt
```

Sau khi hoàn tất, hãy nhấn **Check** để hệ thống kiểm tra trạng thái hoạt động của Redis Exporter.
