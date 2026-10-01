# Bước 3: Tìm Kiếm Tệp Tin & Nội Dung Với find và grep

Khi tiếp quản một hệ thống lớn với hàng nghìn tệp tin mã nguồn và cấu hình, hai kỹ năng tìm kiếm sau đây là công cụ sống còn của kỹ sư vận hành:
1. **Tìm kiếm tệp tin theo tên/thuộc tính:** Sử dụng `find`.
2. **Tìm kiếm nội dung bên trong tệp tin:** Sử dụng `grep`.

---

## 1. Tìm Kiếm Tệp Tin Với Lệnh `find`

Lệnh `find` quét qua cây thư mục từ trên xuống dưới và tìm các tệp tin hoặc thư mục khớp với tiêu chí bạn đưa ra.

Cú pháp:
```text
find <thư_mục_bắt_đầu> [tiêu_chí]
```

### Các tiêu chí tìm kiếm phổ biến:
- **Theo tên tệp (`-name` hoặc `-iname`):**
  - `-name "*.log"`: Tìm các file kết thúc bằng `.log` (phân biệt hoa thường).
  - `-iname "*.env"`: Tìm file không phân biệt hoa thường (tìm cả `.env` lẫn `.ENV`).
- **Theo loại đối tượng (`-type`):**
  - `-type f`: Chỉ tìm các tệp tin thông thường (file).
  - `-type d`: Chỉ tìm thư mục (directory).
- **Theo dung lượng (`-size`):**
  - `-size +10M`: Tìm các file lớn hơn 10 Megabytes.
  - `-size -100k`: Tìm các file nhỏ hơn 100 Kilobytes.
- **Giới hạn độ sâu quét (`-maxdepth`):**
  - `-maxdepth 2`: Chỉ tìm sâu tối đa 2 cấp thư mục, giúp tăng tốc độ tìm kiếm.

### Ví dụ thực hành:
```bash
# Tìm tất cả các file cấu hình trong /opt
find /opt -type f -name "*.conf"
```{{exec}}

---

## 2. Tìm Kiếm Nội Dung Đệ Quy Với `grep`

Khi bạn cần tìm vị trí khai báo của một biến môi trường, một URL kết nối database hoặc truy vết một mã lỗi cụ thể trong hàng loạt file dự án, `grep` là công cụ mạnh mẽ nhất.

### Các cờ hiệu kinh điển khi tìm kiếm nội dung:
- **`-r` hoặc `-R` (Recursive):** Tìm kiếm đệ quy xuyên suốt tất cả các thư mục con.
- **`-n` (Line number):** Hiển thị chính xác số dòng tìm thấy từ khóa (rất thuận tiện để mở code sửa lỗi).
- **`-i` (Ignore case):** Bỏ qua sự khác biệt giữa chữ hoa và chữ thường.
- **`-l` (Files with matches):** Chỉ in ra đường dẫn của những file có chứa từ khóa, ẩn nội dung chi tiết.

### Bộ đôi "thần thánh" trong DevOps:
```bash
grep -rn "từ_khóa" /đường/dẫn/thư/mục
```
Lệnh này vừa tìm đệ quy toàn bộ thư mục, vừa in rõ tên file và số dòng chứa từ khóa!

---

## 3. Khảo Sát Kiến Trúc Microservices Mẫu

Hệ thống đã chuẩn bị sẵn một kiến trúc microservices phân tầng phức tạp tại `/opt/microservices`. Hãy quan sát cây thư mục:

```bash
tree /opt/microservices
```{{exec}}

---

## 4. Thử Thách Bước 3: Rà Soát Bảo Mật & Truy Vết Khóa Bí Mật

**Nhiệm vụ của bạn:**
Hãy thực hiện cuộc rà soát an ninh trên thư mục `/opt/microservices`:

1. **Tìm kiếm các tệp cấu hình môi trường:**
   Dùng lệnh `find` để tìm toàn bộ các tệp tin (file) có đuôi `.env` bên trong `/opt/microservices` và lưu danh sách vào tệp `/tmp/found-env-files.txt` (khuyến khích sắp xếp bằng `sort`):
   ```bash
   find /opt/microservices -type f -name "*.env" | sort > /tmp/found-env-files.txt
   ```

2. **Truy vết các khóa bí mật bị rò rỉ:**
   Dùng lệnh `grep -rn` tìm kiếm đệ quy từ khóa `SECRET_KEY` trong toàn bộ thư mục `/opt/microservices` và lưu kết quả phát hiện vào tệp `/tmp/leak-keys.txt` (khuyến khích sắp xếp bằng `sort`):
   ```bash
   grep -rn "SECRET_KEY" /opt/microservices | sort > /tmp/leak-keys.txt
   ```

3. **Kiểm tra kết quả rà soát:**
   ```bash
   cat /tmp/found-env-files.txt
   cat /tmp/leak-keys.txt
   ```

Sau khi hoàn tất, hãy bấm **Check** để hệ thống tự động kiểm tra và nghiệm thu kết quả bài làm của bạn!
