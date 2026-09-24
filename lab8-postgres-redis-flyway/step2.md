# Bước 2: Quản Lý Phiên Bản Database Với Flyway & Kiểm Tra Tính Toàn Vẹn CSDL

Trong quy trình DevOps và CI/CD, việc cập nhật cơ sở dữ liệu bằng cách chạy câu lệnh SQL thủ công là nguồn gốc của hầu hết các sự cố nghiêm trọng (lệch cấu trúc bảng giữa Staging và Production, thiếu trường, thiếu khóa ngoại). **Flyway** mang lại giải pháp **Database Migration as Code** giúp kiểm soát phiên bản CSDL như mã nguồn Git.

---

## 1. Nguyên Lý Hoạt Động Của Flyway

Flyway theo dõi trạng thái cơ sở dữ liệu thông qua bảng siêu dữ liệu đặc biệt có tên là **`flyway_schema_history`**:
- Mỗi khi bạn thêm một file migration mới, Flyway so sánh phiên bản trong thư mục với các phiên bản đã ghi nhận trong bảng lịch sử.
- Flyway tính toán mã băm **Checksum** của từng file. Nếu có ai đó lén chỉnh sửa nội dung của file migration đã chạy trong quá khứ, Flyway sẽ lập tức phát hiện và chặn quá trình triển khai (`Checksum mismatch`).

### Quy ước đặt tên file nghiêm ngặt:
```text
V<Version>__<Description>.sql
```
- Bắt đầu bằng chữ cái `V` viết hoa.
- Tiếp theo là số thứ tự phiên bản (`1`, `2`, `2.1`, hoặc định dạng timestamp `20260924`).
- Ký tự phân cách: **2 dấu gạch dưới** `__`.
- Mô tả ngắn gọn thay đổi (viết cách nhau bằng dấu gạch dưới hoặc gạch nối).
- Đuôi mở rộng: `.sql`.

Ví dụ hợp lệ: `V1__create_users_table.sql`, `V2__add_orders_table.sql`.

---

## 2. Các Lệnh Flyway Cốt Lõi

| Lệnh Flyway | Ý Nghĩa Thực Chiến |
|---|---|
| **`flyway info`** | Hiển thị bảng tổng hợp trạng thái các migration (Pending, Success, Failed, Missing) |
| **`flyway migrate`** | Quét thư mục migration và thực thi tuần tự các file chưa chạy vào cơ sở dữ liệu |
| **`flyway validate`** | Kiểm tra tính toàn vẹn: so sánh checksum file trên đĩa với bản ghi trong DB để chống gian lận |
| **`flyway baseline`** | Đánh dấu phiên bản khởi đầu cho một cơ sở dữ liệu đã có sẵn dữ liệu từ trước |

---

## 3. Tạo Bản Migration Đầu Tiên (`V1`)

Tạo file kịch bản tạo bảng người dùng tại `/root/migrations/V1__create_users_table.sql`:

```bash
cat << 'EOF' > /root/migrations/V1__create_users_table.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
```{{exec}}

Kiểm tra trạng thái migration trước khi chạy:

```bash
flyway info
```{{exec}}

Bạn sẽ thấy phiên bản `1` đang ở trạng thái `Pending`. Tiến hành áp dụng migration:

```bash
flyway migrate
```{{exec}}

Kiểm tra lại bằng `flyway info` — trạng thái đã chuyển thành `Success`.

Dùng `psql` để soi bảng siêu dữ liệu mà Flyway tự động sinh ra:

```bash
psql -c "SELECT version, description, type, installed_by, success FROM flyway_schema_history;"
```{{exec}}

---

## 4. Kiểm Tra Tính Toàn Vẹn CSDL Sau Migration (Integrity Checks)

Sau khi chạy migration, một kỹ sư DevOps phải kiểm tra hai khía cạnh toàn vẹn:

### 1. Kiểm tra toàn vẹn kịch bản (Script Checksum Integrity):
```bash
flyway validate
```{{exec}}

Nếu file migration trên đĩa bị thay đổi dù chỉ 1 dấu cách sau khi đã chạy, lệnh này sẽ báo lỗi, ngăn chặn rủi ro sai lệch môi trường.

### 2. Kiểm tra toàn vẹn ràng buộc CSDL (Constraint Integrity):
Thêm một người dùng mẫu:
```bash
psql -c "INSERT INTO users (username, email) VALUES ('alice', 'alice@devops.local');"
```{{exec}}

Thử chèn tiếp một bản ghi có cùng email:
```bash
psql -c "INSERT INTO users (username, email) VALUES ('bob', 'alice@devops.local');" 2>&1 || true
```{{exec}}

PostgreSQL ngay lập tức trả về lỗi vi phạm ràng buộc `UNIQUE (email)` — chứng minh migration đã thiết lập ràng buộc toàn vẹn dữ liệu thành công!

---

## 5. Thử Thách & Xác Thực (Verification)

Mở rộng cấu trúc cơ sở dữ liệu để hỗ trợ tính năng mua hàng, có ràng buộc khóa ngoại liên kết tới bảng `users`.

### Yêu cầu thử thách:
1. Đảm bảo file cấu hình `/root/flyway.conf` sử dụng user quản trị ứng dụng:
   - `flyway.user=store_admin`
   - `flyway.password=admin_secret_999`
2. Tạo file migration thứ hai tại `/root/migrations/V2__create_products_and_orders.sql`:
   - Bảng **`products`**:
     - `id SERIAL PRIMARY KEY`
     - `name VARCHAR(100) NOT NULL`
     - `price NUMERIC(10, 2) NOT NULL`
     - `stock INTEGER DEFAULT 0`
   - Bảng **`orders`**:
     - `id SERIAL PRIMARY KEY`
     - `user_id INTEGER NOT NULL`
     - `total_amount NUMERIC(10, 2) NOT NULL`
     - `status VARCHAR(20) DEFAULT 'pending'`
     - `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
     - **Ràng buộc khóa ngoại bắt buộc**: `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
3. Chạy lệnh:
   ```bash
   flyway migrate
   ```
4. **Kiểm tra tính toàn vẹn của kết nối và dữ liệu**:
   - Chạy lệnh `flyway validate` để xác nhận toàn bộ migration đều khớp checksum hợp lệ.
   - Thực hiện kiểm tra toàn vẹn khóa ngoại bằng lệnh `psql`: Thử chèn một đơn hàng với `user_id = 9999` (ID người dùng chưa hề tồn tại):
     ```bash
     psql -U store_admin -d ecommerce_db -c "INSERT INTO orders (user_id, total_amount) VALUES (9999, 150.00);"
     ```
     Xác nhận hệ thống trả về lỗi từ chối vi phạm khóa ngoại: `violates foreign key constraint`.
5. Kiểm tra bằng lệnh `flyway info` để thấy cả 2 phiên bản đều có trạng thái `Success`.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý mã nguồn file migration V2</summary>

Cập nhật `/root/flyway.conf`:
```properties
flyway.url=jdbc:postgresql://localhost:5432/ecommerce_db
flyway.user=store_admin
flyway.password=admin_secret_999
flyway.locations=filesystem:/flyway/sql
flyway.baselineOnMigrate=true
```

Tạo file `/root/migrations/V2__create_products_and_orders.sql`:
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

Chạy migration và kiểm tra tính toàn vẹn:
```bash
flyway migrate
flyway validate
flyway info
```

</details>

Sau khi hoàn thành và cả 2 migration đạt trạng thái `Success`, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
