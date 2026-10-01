# Bước 2: Làm Chủ Lệnh chmod — Phương Pháp Ký Hiệu & Số Bát Phân

Lệnh `chmod` (**Change Mode**) là công cụ then chốt trong Linux dùng để thay đổi quyền truy cập của người dùng đối với tệp tin và thư mục.

Có hai phương pháp phân quyền phổ biến: **Dạng Ký Hiệu (Symbolic Mode)** và **Dạng Số Bát Phân (Octal Mode)**.

---

## 1. Phương Pháp Ký Hiệu (Symbolic Mode)

Phương pháp này thích hợp khi bạn muốn bổ sung hoặc tước bớt một quyền cụ thể (ví dụ: chỉ thêm quyền thực thi `x`) mà không làm thay đổi các quyền hiện có.

Cú pháp:
```text
chmod [đối_tượng] [toán_tử] [quyền] <tệp_tin>
```

- **Đối tượng tác động:**
  - `u` (User): Chủ sở hữu
  - `g` (Group): Nhóm người dùng
  - `o` (Others): Những người còn lại
  - `a` (All): Áp dụng cho cả 3 đối tượng (`ugo`)
- **Toán tử:**
  - `+`: Thêm quyền
  - `-`: Tước bỏ quyền
  - `=`: Gán quyền chính xác (ghi đè quyền cũ)
- **Quyền:** `r`, `w`, `x`

### Ví dụ thực tế:
- Cấp quyền thực thi cho tất cả mọi người đối với một script:
  ```bash
  chmod +x /path/to/script.sh
  ```
- Tước bỏ quyền ghi của nhóm và người ngoài:
  ```bash
  chmod go-w /path/to/file.txt
  ```

---

## 2. Phương Pháp Số Bát Phân (Octal / Numeric Mode)

Đây là phương pháp tiêu chuẩn trong DevOps, được sử dụng trong hầu hết các script triển khai, Dockerfile và tài liệu kỹ thuật nhờ tính ngắn gọn và chuẩn xác tuyệt đối.

Mỗi quyền hạn được đại diện bằng một giá trị số theo lũy thừa của 2:

```
  r (Read)    = 4
  w (Write)   = 2
  x (Execute) = 1
  - (None)    = 0
```

Bằng cách cộng dồn các giá trị này lại, ta có tổng điểm từ 0 đến 7 cho mỗi nhóm đối tượng:

| Tổng Giá Trị Số | Biểu Diễn Ký Tự | Ý Nghĩa Thực Tế |
|---|---|---|
| **7** (4 + 2 + 1) | `rwx` | Toàn quyền: Đọc, Ghi và Thực thi |
| **6** (4 + 2 + 0) | `rw-` | Quyền Đọc và Ghi (không cho chạy script) |
| **5** (4 + 0 + 1) | `r-x` | Quyền Đọc và Thực thi (không cho sửa file) |
| **4** (4 + 0 + 0) | `r--` | Quyền Chỉ đọc |
| **0** (0 + 0 + 0) | `---` | Chặn hoàn toàn, không có bất kỳ quyền nào |

---

## 3. Bốn Mức Quyền Kinh Điển Trong Vận Hành Hệ Thống

Một lệnh `chmod` dạng số luôn nhận **3 chữ số** tương ứng với `[User][Group][Others]`:

```
  chmod   7      5      5    deploy.sh
          |      |      |
          |      |      +--> Others: 5 (r-x: đọc & chạy)
          |      +---------> Group:  5 (r-x: đọc & chạy)
          +----------------> User:   7 (rwx: toàn quyền)
```

1. **`chmod 755 <script_hoặc_thư_mục>`:** 
   - User có toàn quyền (`rwx`), Group và Others được đọc và thực thi (`r-x`).
   - Đây là chuẩn mực cho các thư mục hệ thống và các script khởi chạy dịch vụ.
2. **`chmod 644 <file_cấu_hình>`:**
   - User được đọc và sửa (`rw-`), Group và Others chỉ được đọc (`r--`).
   - Đây là chuẩn mực cho file source code, web HTML/CSS, cấu hình `.env` hoặc cấu hình Nginx.
3. **`chmod 600 <private_key>`:**
   - Chỉ duy nhất User được đọc và ghi (`rw-`), Group và Others bị chặn hoàn toàn (`---`).
   - Bắt buộc phải dùng cho SSH Private Key (`~/.ssh/id_rsa`, `id_ed25519`). Nếu bạn để quyền khác (như 644 hay 777), OpenSSH sẽ từ chối kết nối ngay lập tức!
4. **`chmod 400 <secret_key>`:**
   - Chỉ duy nhất User có quyền đọc (`r--`). Thường dùng cho các file token bảo mật hoặc khóa `.pem` trên AWS EC2.

> **Áp dụng đệ quy cho cả thư mục:**
> Sử dụng cờ `-R` (viết hoa): `chmod -R 755 /var/www/my-website` để áp dụng quyền cho thư mục và toàn bộ cây con bên trong.

---

## 4. Thử Thách Bước 2: Gia Cố Bảo Mật Dịch Vụ Ứng Dụng

**Bối cảnh:**
Trong thư mục `/opt/secure-service`, quản trị viên cũ đã bất cẩn thiết lập quyền `777` (cho phép toàn thế giới đọc, ghi, xóa và chạy) đối với tất cả các tệp nhạy cảm. Đây là một lỗ hổng an ninh nghiêm trọng!

Hãy kiểm tra trạng thái hiện tại:

```bash
ls -l /opt/secure-service
```{{exec}}

**Nhiệm vụ của bạn:**
Hãy sử dụng lệnh `chmod` với phương pháp số bát phân để tái thiết lập quyền chuẩn an toàn cho 3 tệp tin:

1. **`deploy.sh`:** Thiết lập quyền **`755`** (`-rwxr-xr-x`) để người dùng có toàn quyền, đồng đội và hệ thống có thể đọc và chạy script triển khai.
2. **`config.env`:** Thiết lập quyền **`644`** (`-rw-r--r--`) để bảo vệ file cấu hình môi trường, chỉ cho phép chủ sở hữu chỉnh sửa.
3. **`service.key`:** Thiết lập quyền **`600`** (`-rw-------`) để cô lập hoàn toàn khóa bí mật, ngăn ngừa rò rỉ dữ liệu.

Sau khi hoàn thành, hãy nhấn nút **Check** để hệ thống kiểm tra và nghiệm thu cấu hình bảo mật của bạn!
