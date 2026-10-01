# Bước 1: Giải Mã Cơ Chế Phân Quyền Linux & Ý Nghĩa rwx

Để kiểm soát quyền truy cập của người dùng và các tiến trình ứng dụng vào dữ liệu, hệ điều hành Linux sử dụng mô hình phân quyền bảo mật dựa trên danh tính người dùng và nhóm.

---

## 1. Mổ Xẻ Kết Quả Lệnh `ls -l`

Khi liệt kê danh sách tệp với cờ `-l` (Long listing format):

```bash
ls -l /opt/audit/company_secrets.txt
```{{exec}}

Bạn sẽ nhìn thấy một dòng kết quả chi tiết tương tự như sau:

```text
-rw-r----- 1 root root 85 Oct  1 14:00 /opt/audit/company_secrets.txt
```

Hãy cùng bóc tách 7 trường thông tin quan trọng này:

```
  -rw-r-----    1     root     root     85     Oct 1 14:00    company_secrets.txt
  |             |     |        |        |      |              |
  |             |     |        |        |      |              +--> Tên tệp tin
  |             |     |        |        |      +-----------------> Thời gian sửa đổi gần nhất
  |             |     |        |        +------------------------> Dung lượng tệp (bytes)
  |             |     |        +---------------------------------> Nhóm sở hữu (Group owner)
  |             |     +------------------------------------------> Người dùng sở hữu (User owner)
  |             +------------------------------------------------> Số lượng Hard Links
  +--------------------------------------------------------------> Chuỗi 10 ký tự phân quyền
```

---

## 2. Giải Mã Chuỗi 10 Ký Tự Phân Quyền

Chuỗi 10 ký tự ở đầu dòng được chia thành 4 phần riêng biệt:

```
    -       rw-       r--       ---
  [ 0 ]   [ 1 2 3 ] [ 4 5 6 ] [ 7 8 9 ]
    |         |         |         |
    |         |         |         +--> Nhóm 3: Quyền của Others (người dùng khác)
    |         |         +------------> Nhóm 2: Quyền của Group (nhóm sở hữu)
    |         +----------------------> Nhóm 1: Quyền của User (chủ sở hữu tệp)
    +--------------------------------> Ký tự 0: Loại tệp tin
```

### Ký tự đầu tiên: Phân loại tệp tin
- **`-` (Dấu gạch ngang):** Tệp tin thông thường (Regular file) — như source code, file text, ảnh, video.
- **`d` (Directory):** Thư mục.
- **`l` (Symbolic Link):** Đường dẫn tắt trỏ tới tệp khác (tương tự shortcut trên Windows).
- **`c` / `b`:** Thiết bị ký tự (Character device) hoặc thiết bị khối (Block device - như ổ cứng `/dev/sda`).

---

## 3. Sự Khác Biệt Sống Còn: `rwx` Trên File vs Trên Thư Mục

Bộ ba quyền cơ bản gồm có:
- **`r` (Read - Đọc)**
- **`w` (Write - Ghi / Sửa)**
- **`x` (Execute - Thực thi)**
- **`-` (Không có quyền - Denied)**

Tuy nhiên, ý nghĩa thực tế của bộ quyền này **hoàn toàn khác nhau** khi áp dụng lên File so với Thư mục:

| Quyền Hạn | Tác Động Lên FILE | Tác Động Lên THƯ MỤC |
|---|---|---|
| **`r` (Read)** | Cho phép mở và đọc nội dung văn bản bên trong file (`cat`, `less`, `head`). | Cho phép xem và liệt kê danh sách các tệp tin/thư mục con bên trong (`ls`). |
| **`w` (Write)** | Cho phép sửa đổi, thêm mới hoặc ghi đè nội dung file (`nano`, `echo >`). | Cho phép **tạo mới, đổi tên hoặc xóa vĩnh viễn** các file bên trong thư mục. |
| **`x` (Execute)** | Cho phép chạy file như một chương trình nhị phân hoặc script (`./deploy.sh`). | Cho phép **bước chân vào thư mục (`cd`)** hoặc truy cập các tệp tin bên trong. |

> **Cảnh Báo Kỹ Thuật Trong DevOps:**
> Nếu một thư mục có quyền `r` nhưng **KHÔNG có quyền `x`**: Bạn có thể dùng `ls` để nhìn thấy tên các file bên trong, nhưng bạn **hoàn toàn không thể `cd` vào** và không thể đọc được nội dung của bất kỳ file nào!

---

## 4. Thực Hành: Khảo Sát Quyền Hạn Thực Tế

Kiểm tra quyền hạn của thư mục `/opt/audit`:

```bash
ls -ld /opt/audit
```{{exec}}

Quan sát thấy: `drwxr-xr-x`
- Ký tự đầu là `d`: Đây là một thư mục.
- User có quyền `rwx`: Có thể đọc danh sách file, tạo/xóa file và `cd` vào bên trong.
- Group và Others có quyền `r-x`: Có thể xem danh sách file và `cd` vào bên trong, nhưng **không có quyền `w`** (không thể tạo hay xóa file của người khác).

---

## 5. Thử Thách Bước 1: Phân Tích Hồ Sơ Bảo Mật Tệp Tin

**Nhiệm vụ của bạn:**
Hãy quan sát quyền hạn của tệp `/opt/audit/company_secrets.txt` bằng lệnh `ls -l`. Sau đó, tạo một tệp báo cáo tại `/tmp/perm-analysis.txt` chứa đúng 4 dòng phân tích theo cấu trúc sau:

```text
FILE_TYPE: regular
USER_PERM: rw-
GROUP_PERM: r--
OTHERS_PERM: ---
```

> **Gợi ý thực hiện:**
> Bạn có thể dùng lệnh `echo` kết hợp toán tử điều hướng `>` và `>>`:
> ```bash
> echo "FILE_TYPE: regular" > /tmp/perm-analysis.txt
> echo "USER_PERM: rw-" >> /tmp/perm-analysis.txt
> echo "GROUP_PERM: r--" >> /tmp/perm-analysis.txt
> echo "OTHERS_PERM: ---" >> /tmp/perm-analysis.txt
> ```
> Dùng lệnh `cat /tmp/perm-analysis.txt` để kiểm tra lại trước khi bấm Check.

Sau khi tạo xong tệp báo cáo, hãy nhấn nút **Check** để hệ thống tự động xác thực kết quả!
