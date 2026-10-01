# Bước 3: Quản Trị Sở Hữu User & Group Với chown và chgrp

Bên cạnh việc thiết lập quyền đọc/ghi/chạy, việc gán **quyền sở hữu (Ownership)** chính xác cho đúng người dùng và nhóm dịch vụ là nền tảng sống còn của an toàn hệ thống.

---

## 1. Tại Sao Phải Phân Tách Quyền Sở Hữu Trong DevOps?

Một trong những sai lầm an ninh phổ biến nhất của người mới là để toàn bộ ứng dụng và tệp tin thuộc sở hữu của tài khoản `root`. 

Khi một tiến trình chạy với quyền `root` bị hacker tấn công qua lỗ hổng mã nguồn (như Remote Code Execution hay SQL Injection), kẻ tấn công sẽ lập tức giành được toàn quyền kiểm soát máy chủ.

> **Chuẩn mực Production:**
> Mỗi dịch vụ (Web, Database, Worker) luôn chạy bằng một tài khoản chuyên biệt với đặc quyền tối thiểu (Non-root service user):
> - Máy chủ Web Nginx chạy dưới user `www-data` hoặc `nginx`.
> - Cơ sở dữ liệu PostgreSQL chạy dưới user `postgres`.
> - Ứng dụng Backend chạy dưới user riêng (ví dụ: `webapps`).

---

## 2. Làm Chủ Lệnh `chown` (Change Owner)

Lệnh `chown` dùng để thay đổi người dùng sở hữu (User Owner) và nhóm sở hữu (Group Owner) của tệp tin hoặc thư mục.

Cú pháp chuẩn:
```text
chown [tùy_chọn] <user>[:group] <đường_dẫn>
```

### Các trường hợp sử dụng kinh điển:
1. **Chỉ đổi người dùng sở hữu:**
   ```bash
   chown webapps /opt/web-service/index.html
   ```
2. **Đổi đồng thời cả người dùng và nhóm sở hữu:**
   ```bash
   chown webapps:developers /opt/web-service/index.html
   ```
3. **Đổi đệ quy cho toàn bộ thư mục và con cháu bên trong (Cờ `-R`):**
   ```bash
   chown -R webapps:developers /opt/web-service
   ```

---

## 3. Lệnh `chgrp` (Change Group)

Nếu bạn chỉ có nhu cầu thay đổi nhóm sở hữu mà muốn giữ nguyên người dùng sở hữu hiện tại, bạn có thể dùng lệnh `chgrp`:

```bash
chgrp developers /opt/web-service/logs
```
hoặc với cờ `-R`:
```bash
chgrp -R developers /opt/web-service/logs
```

> **Mẹo nhanh:** Bạn hoàn toàn có thể làm điều tương tự với `chown` bằng cách đặt dấu hai chấm trước tên nhóm: `chown :developers /opt/web-service/logs`.

---

## 4. Thử Thách Bước 3: Cấu Hình Phân Quyền Dịch Vụ Web Chuẩn Production

**Bối cảnh:**
Hệ thống vừa triển khai một dịch vụ web mới tại thư mục `/opt/web-service`. Hiện tại toàn bộ thư mục này đang bị gán sở hữu cho `root:root` và khóa chặt quyền `700`, khiến các lập trình viên trong nhóm `developers` và tiến trình `webapps` không thể hoạt động.

Hãy kiểm tra trạng thái hiện tại:

```bash
ls -ld /opt/web-service
ls -la /opt/web-service
```{{exec}}

**Nhiệm vụ của bạn:**
Thực hiện chính xác các bước cấu hình sau:

1. **Chuyển quyền sở hữu đệ quy:**
   Chuyển toàn bộ quyền sở hữu của thư mục `/opt/web-service` và toàn bộ tệp bên trong cho người dùng `webapps` và nhóm `developers`:
   ```bash
   chown -R webapps:developers /opt/web-service
   ```

2. **Cấu hình quyền thư mục gốc:**
   Thiết lập quyền của thư mục gốc `/opt/web-service` thành **`755`** (`rwxr-xr-x`):
   ```bash
   chmod 755 /opt/web-service
   ```

3. **Cấu hình quyền tệp web tĩnh:**
   Thiết lập quyền của tệp `/opt/web-service/index.html` thành **`644`** (`rw-r--r--`):
   ```bash
   chmod 644 /opt/web-service/index.html
   ```

4. **Cấu hình quyền thư mục Logs:**
   Thư mục `/opt/web-service/logs` cần cho phép cả User `webapps` và các thành viên trong nhóm `developers` có quyền ghi log và dọn log. Hãy thiết lập quyền thành **`775`** (`rwxrwxr-x`):
   ```bash
   chmod 775 /opt/web-service/logs
   ```

5. **Kiểm tra lại thành quả:**
   ```bash
   ls -la /opt/web-service
   ls -ld /opt/web-service/logs
   ```

Sau khi hoàn tất, hãy bấm **Check** để hệ thống tự động kiểm tra và đánh giá toàn bộ kiến trúc phân quyền của bạn!
