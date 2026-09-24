# Bước 3: Tích Hợp Ứng Dụng Với Connection Pool & Mô Hình Caching (Cache-Aside)

Trong bước cuối cùng, bạn sẽ kết nối toàn bộ các thành phần đã xây dựng thành một kiến trúc hoàn chỉnh: ứng dụng đọc cấu hình an toàn từ biến môi trường, quản lý kết nối CSDL qua **Connection Pool**, tự động hóa dòng chảy dữ liệu với mô hình **Cache-Aside Pattern** và kiểm tra tính toàn vẹn dữ liệu xuyên suốt.

---

## 1. Mô Hình Cache-Aside Pattern (Lazy Loading)

Cache-Aside là mẫu thiết kế bộ nhớ đệm phổ biến nhất trong kiến trúc Microservices và Web backend:

```text
               ┌───────────────────────┐
               │    Client Request     │
               └───────────┬───────────┘
                           │ 1. Get Product
                           ▼
               ┌───────────────────────┐
        ┌──────┤  Application Service  ├──────┐
        │      └───────────────────────┘      │
        │ 2. Check Cache                      │ 4. Query DB (Cache Miss)
        ▼                                     ▼
┌───────────────┐                     ┌───────────────┐
│  Redis Cache  │                     │  PostgreSQL   │
│  (In-Memory)  │                     │  (Persistent) │
└───────┬───────┘                     └───────┬───────┘
        │ 3. Return (Cache Hit)               │ 5. Save to Cache with TTL
        └─────────────────────────────────────┘
```

### Nguyên lý dòng chảy dữ liệu:
1. **Kiểm tra Cache trước**: Khi có yêu cầu đọc thông tin sản phẩm, ứng dụng kiểm tra Redis bằng key `product:<id>`.
2. **Cache Hit (Trúng cache)**: Nếu key tồn tại trong Redis, trả về dữ liệu ngay từ RAM (độ trễ < 1ms). Hoàn toàn không tốn tài nguyên truy vấn PostgreSQL.
3. **Cache Miss (Trượt cache)**: Nếu key chưa có trong Redis:
   - Ứng dụng lấy một kết nối từ **Connection Pool**.
   - Thực thi truy vấn `SELECT` vào bảng `products` trong PostgreSQL.
   - Trả kết nối về Pool để các request khác tái sử dụng.
   - Lưu kết quả vừa truy vấn vào Redis kèm thời gian sống `TTL` (ví dụ: 60 giây).
   - Trả kết quả cho Client.

---

## 2. Kiểm Tra Tính Toàn Vẹn Kết Nối & Hiệu Năng

### 1. Tính toàn vẹn kết nối (Connection Pool Integrity):
Khi nhiều request được gửi đồng thời, Connection Pool tái sử dụng các TCP socket đã mở sẵn, giúp:
- Tỷ lệ lỗi kết nối: **0%**.
- Thời gian chờ socket: Giảm từ ~50ms xuống gần như bằng 0ms.
- Số lượng tiến trình trên PostgreSQL luôn nằm trong khoảng `DB_POOL_MIN` đến `DB_POOL_MAX`, không gây quá tải CPU máy chủ CSDL.

### 2. So sánh độ trễ (Latency Comparison):
- **Lần 1 (Cache Miss)**: Ứng dụng phải đọc dữ liệu từ ổ đĩa của PostgreSQL, mất khoảng `15ms – 30ms`.
- **Lần 2 trở đi (Cache Hit)**: Dữ liệu được nạp trực tiếp từ bộ nhớ RAM của Redis, thời gian phản hồi chỉ còn `0.5ms – 1ms` (nhanh gấp 30 lần!).

---

## 3. Thử Thách & Xác Thực (Verification)

Hãy thực hành đưa dữ liệu sản phẩm mới vào PostgreSQL và kích hoạt cơ chế Cache-Aside đồng bộ sang Redis.

### Yêu cầu thử thách:
1. Đứng tại thư mục `/root/app`.
2. Dùng lệnh `psql` (với user `store_admin` hoặc `postgres`) chèn một bản ghi sản phẩm mới vào bảng `products`:
   - Name: `DevOps Mechanical Keyboard`
   - Price: `120.00`
   - Stock: `50`
3. Lấy `id` của sản phẩm vừa tạo (sản phẩm đầu tiên sẽ có `id = 1`).
4. Sử dụng lệnh `redis-cli` mô phỏng hành vi Cache-Aside của ứng dụng:
   - Key: `product:1:data`
   - Value: Chuỗi JSON: `{"id":1,"name":"DevOps Mechanical Keyboard","price":120.00,"stock":50}`
   - Thiết lập thời gian sống (TTL): `60` giây (`EX 60`).
5. **Kiểm tra tính toàn vẹn dữ liệu**:
   - Truy vấn CSDL gốc: `psql -c "SELECT * FROM products WHERE id=1;"`.
   - Đọc dữ liệu từ Cache: `redis-cli GET product:1:data`.
   - Xác nhận dữ liệu trong Redis khớp chính xác 100% với dữ liệu trong PostgreSQL và `redis-cli TTL product:1:data` đang đếm ngược lớn hơn 0.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Chèn sản phẩm vào PostgreSQL:
```bash
psql -U store_admin -d ecommerce_db -c "INSERT INTO products (name, price, stock) VALUES ('DevOps Mechanical Keyboard', 120.00, 50);"
```

Kiểm tra sản phẩm đã có trong bảng:
```bash
psql -U store_admin -d ecommerce_db -c "SELECT id, name, price, stock FROM products;"
```

Lưu dữ liệu vào Redis theo mẫu Cache-Aside:
```bash
redis-cli SET product:1:data '{"id":1,"name":"DevOps Mechanical Keyboard","price":120.00,"stock":50}' EX 60
```

Kiểm tra tính toàn vẹn và thời gian sống TTL:
```bash
redis-cli GET product:1:data
redis-cli TTL product:1:data
```

</details>

Sau khi hoàn thành và dữ liệu đồng bộ thành công giữa hai hệ thống, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
