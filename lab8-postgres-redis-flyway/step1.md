# Bước 1: Triển Khai Kết Nối An Toàn Qua Biến Môi Trường & Connection Pooling

Trong bước đầu tiên, bạn sẽ tìm hiểu nguyên tắc quản lý kết nối an toàn theo chuẩn 12-Factor App, hiểu rõ vai trò sống còn của Connection Pooling trong việc tối ưu tài nguyên cơ sở dữ liệu, và thực hành tương tác trực tiếp với hai dịch vụ PostgreSQL và Redis.

---

## 1. Quản Lý Kết Nối Qua Biến Môi Trường (12-Factor App)

Trong các hệ thống Cloud-Native và quy trình CI/CD chuyên nghiệp:
- **Tuyệt đối không lưu mật khẩu hoặc chuỗi kết nối cứng (hardcoded) trong mã nguồn**. Nếu mã nguồn được đẩy lên Git repository công khai hoặc chia sẻ nội bộ, thông tin đăng nhập sẽ bị lộ.
- Thông tin nhạy cảm phải được truyền vào ứng dụng dưới dạng **Biến Môi Trường (Environment Variables)** thông qua file cấu hình `.env` hoặc hệ thống quản lý secret (HashiCorp Vault, AWS Secrets Manager, Kubernetes Secrets).

Chuỗi kết nối (Connection String) chuẩn:
- **PostgreSQL**: `postgresql://<user>:<password>@<host>:<port>/<database>`
- **Redis**: `redis://<host>:<port>/<db_index>`

---

## 2. Bản Chất & Tầm Quan Trọng Của Connection Pooling

Khi ứng dụng web xử lý hàng nghìn request mỗi phút, việc quản lý kết nối đến cơ sở dữ liệu quyết định sự sống còn của toàn bộ hệ thống:

### Chi phí đắt đỏ khi không có Connection Pool:
- Trong PostgreSQL, mỗi kết nối TCP mới tương ứng với một tiến trình backend riêng biệt được tạo ra (`fork`) ở tầng hệ điều hành.
- Quá trình bắt tay 3 bước TCP (3-Way Handshake) + xác thực mật khẩu + cấp phát bộ nhớ tiêu tốn từ 20ms đến 100ms và chiếm dụng khoảng 10MB RAM cho mỗi tiến trình.
- Nếu 200 request đồng thời cùng mở kết nối mới, máy chủ sẽ bị nghẽn CPU và cạn kiệt bộ nhớ ngay lập tức.

### Cơ chế hoạt động của Connection Pool:
- **Khởi tạo sẵn một nhóm kết nối (Pool)**: Duy trì một số lượng kết nối tối thiểu (`DB_POOL_MIN`) luôn mở sẵn ở trạng thái rảnh (idle).
- **Tái sử dụng (Reuse)**: Khi có truy vấn, ứng dụng mượn một kết nối từ pool, thực thi xong sẽ trả kết nối về pool thay vì đóng socket.
- **Giới hạn an toàn (`DB_POOL_MAX`)**: Ngăn chặn ứng dụng mở quá nhiều kết nối vượt quá ngưỡng chịu tải của máy chủ CSDL.

---

## 3. Thực Hành Thao Tác Với PostgreSQL

Kiểm tra kết nối và phiên bản PostgreSQL đang chạy:

```bash
psql -c "SELECT version();"
```{{exec}}

Xem thông tin kết nối hiện tại:

```bash
psql -c "\conninfo"
```{{exec}}

Liệt kê các cơ sở dữ liệu có sẵn:

```bash
psql -c "\l"
```{{exec}}

Tạo người dùng ứng dụng mới và cấp quyền:

```bash
psql -c "CREATE USER app_user WITH PASSWORD 'app_secret_123';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO app_user;"
```{{exec}}

---

## 4. Thực Hành Thao Tác Với Redis

Kiểm tra kết nối tới Redis (gửi `PING`, nhận về `PONG`):

```bash
redis-cli PING
```{{exec}}

Ghi và đọc dữ liệu dạng Key-Value:

```bash
redis-cli SET app:env "production"
redis-cli GET app:env
```{{exec}}

### Quản lý thời gian sống (TTL - Time To Live):
Bộ nhớ RAM là hữu hạn. Mọi dữ liệu cache đều cần có thời gian hết hạn (`EX` tính theo giây) để tránh tràn bộ nhớ:

```bash
redis-cli SET session:demo "token_999" EX 30
redis-cli TTL session:demo
```{{exec}}

Lệnh `TTL` sẽ trả về số giây còn lại trước khi key tự động bị xóa khỏi bộ nhớ.

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy thiết lập thông tin chứng thực chuyên biệt cho ứng dụng và cấu hình file biến môi trường an toàn.

### Yêu cầu thử thách:
1. Kết nối vào PostgreSQL bằng lệnh `psql` và thực hiện:
   - Tạo user mới tên là `store_admin` với mật khẩu `admin_secret_999`.
   - Cấp toàn quyền trên database `ecommerce_db` cho user này:
     ```sql
     GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO store_admin;
     ALTER DATABASE ecommerce_db OWNER TO store_admin;
     ```
2. Tạo file cấu hình môi trường an toàn tại `/root/app/.env` chứa đầy đủ các biến kết nối và tham số Connection Pool:
   ```text
   DATABASE_URL=postgresql://store_admin:admin_secret_999@localhost:5432/ecommerce_db
   DB_POOL_MIN=2
   DB_POOL_MAX=10
   DB_POOL_TIMEOUT=30
   REDIS_URL=redis://localhost:6379/0
   CACHE_TTL=60
   ```
3. Trong Redis, tạo một khóa lưu phiên làm việc của quản trị viên:
   - Key: `session:token:xyz`
   - Value: `active_admin_session`
   - Thiết lập thời gian sống (TTL): `120` giây (`EX 120`).
4. Tự kiểm tra kết quả:
   - Dùng lệnh `psql -U store_admin -d ecommerce_db -c "SELECT current_user;"` để xác nhận kết nối thành công với user `store_admin`.
   - Dùng lệnh `redis-cli TTL session:token:xyz` để xác nhận key tồn tại và đang đếm ngược thời gian sống.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Tạo user trong PostgreSQL:
```bash
psql -c "CREATE USER store_admin WITH PASSWORD 'admin_secret_999';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO store_admin;"
psql -c "ALTER DATABASE ecommerce_db OWNER TO store_admin;"
```

Tạo file biến môi trường:
```bash
cat << 'EOF' > /root/app/.env
DATABASE_URL=postgresql://store_admin:admin_secret_999@localhost:5432/ecommerce_db
DB_POOL_MIN=2
DB_POOL_MAX=10
DB_POOL_TIMEOUT=30
REDIS_URL=redis://localhost:6379/0
CACHE_TTL=60
EOF
```

Lưu session key vào Redis kèm TTL:
```bash
redis-cli SET session:token:xyz "active_admin_session" EX 120
```

Kiểm tra:
```bash
psql -U store_admin -d ecommerce_db -c "SELECT current_user;"
redis-cli TTL session:token:xyz
```

</details>

Sau khi hoàn thành và tự kiểm tra thành công, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
