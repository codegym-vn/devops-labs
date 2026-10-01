# Bước 1: 3 Luồng Dữ Liệu Chuẩn & Kỹ Thuật Chuyển Hướng

Trong Linux, bất kỳ tiến trình nào khi khởi chạy đều được gắn sẵn 3 kênh giao tiếp dữ liệu chuẩn được định danh bằng các số hiệu mô tả tệp (**File Descriptors**).

---

## 1. Bản Chất Của 3 Luồng Dữ Liệu Chuẩn

| Số Hiệu (FD) | Tên Luồng | Kênh Mặc Định | Ý Nghĩa Thực Tế |
|:---:|---|---|---|
| **`0`** | **`stdin` (Standard Input)** | Bàn phím | Tiếp nhận dữ liệu đầu vào cho chương trình |
| **`1`** | **`stdout` (Standard Output)**| Màn hình Terminal | Xuất kết quả xử lý thành công của lệnh |
| **`2`** | **`stderr` (Standard Error)** | Màn hình Terminal | Xuất các thông báo lỗi và cảnh báo sự cố |

> **Tại sao Linux lại tách riêng `stdout` và `stderr`?**
> Cả hai luồng mặc định đều in chữ ra màn hình terminal nên bằng mắt thường bạn khó nhận ra sự khác biệt. Tuy nhiên, việc tách riêng kênh `1` và kênh `2` cho phép hệ thống tự động:
> - Chỉ lưu kết quả tính toán thành công vào cơ sở dữ liệu.
> - Bắt riêng các dòng thông báo lỗi để kích hoạt chuông cảnh báo tới kỹ sư trực hệ thống.

---

## 2. Bảng Toán Tử Chuyển Hướng (Redirection Operators)

| Toán Tử | Chức Năng | Ví Dụ Thực Tế |
|---|---|---|
| **`>`** | Chuyển hướng `stdout`, **ghi đè** tệp đích | `echo "ok" > status.txt` |
| **`>>`** | Chuyển hướng `stdout`, **ghi nối tiếp** vào cuối tệp | `date >> uptime.log` |
| **`<`** | Chuyển hướng `stdin` (đọc dữ liệu từ tệp đưa vào lệnh) | `cat < config.env` |
| **`2>`** | Chuyển hướng riêng luồng lỗi **`stderr`** ra tệp | `backup.sh 2> backup_error.log` |
| **`2>&1`** | Hợp nhất luồng lỗi `2` vào chung kênh với luồng `1` | `deploy.sh > deploy.log 2>&1` |
| **`&>`** | Cú pháp rút gọn hợp nhất cả `stdout` và `stderr` | `deploy.sh &> deploy.log` |

### Thiết bị đặc biệt: Hố đen `/dev/null`
Trong Linux, `/dev/null` là một tệp thiết bị đặc biệt có chức năng nuốt sạch mọi dữ liệu gửi vào nó mà không tốn dung lượng ổ cứng. 
- Khi bạn muốn chạy một lệnh hoàn toàn yên lặng (Silent mode) trong script:
  ```bash
  command > /dev/null 2>&1
  ```

---

## 3. Khảo Sát Script Chẩn Đoán Thực Tế

Hệ thống đã chuẩn bị sẵn một script chẩn đoán tại `/opt/diagnostic.sh`. Hãy chạy thử:

```bash
/opt/diagnostic.sh
```{{exec}}

Quan sát kết quả trên màn hình:
- Có những dòng hiển thị `[OK]` (được gửi qua kênh `stdout`).
- Có những dòng hiển thị `[ERROR]` (được gửi qua kênh `stderr`).

---

## 4. Thử Thách Bước 1: Phân Tách Và Hợp Nhất Luồng Dữ Liệu

**Nhiệm vụ của bạn:**
Sử dụng các toán tử chuyển hướng để xử lý các luồng output phát sinh từ `/opt/diagnostic.sh`:

1. **Trích xuất riêng kết quả thành công:**
   Chạy `/opt/diagnostic.sh`, chuyển hướng riêng luồng `stdout` vào tệp `/tmp/diag-output.txt` và loại bỏ luồng lỗi bằng `/dev/null`:
   ```bash
   /opt/diagnostic.sh > /tmp/diag-output.txt 2> /dev/null
   ```

2. **Trích xuất riêng thông báo lỗi:**
   Chạy `/opt/diagnostic.sh`, chuyển hướng riêng luồng lỗi `stderr` vào tệp `/tmp/diag-error.txt` và loại bỏ luồng kết quả chuẩn bằng `/dev/null`:
   ```bash
   /opt/diagnostic.sh 2> /tmp/diag-error.txt > /dev/null
   ```

3. **Hợp nhất toàn bộ nhật ký:**
   Chạy `/opt/diagnostic.sh` và chuyển hướng hợp nhất cả hai luồng `stdout` và `stderr` vào chung một tệp `/tmp/diag-combined.txt`:
   ```bash
   /opt/diagnostic.sh > /tmp/diag-combined.txt 2>&1
   ```

Sau khi hoàn thành, hãy kiểm tra lại nội dung 3 tệp bằng lệnh `cat` và nhấn nút **Check** để hệ thống kiểm tra kết quả!
