# Bước 3: Đọc, Xem & Theo Dõi Nội Dung Tệp Tin

Trong quá trình vận hành hệ thống, đọc và chẩn đoán các tệp nhật ký (log files) và tệp cấu hình là hoạt động diễn ra liên tục. Linux cung cấp một bộ công cụ chuyên dụng giúp bạn đọc nội dung hiệu quả mà không làm quá tải terminal hay bộ nhớ.

---

## 1. Đọc Toàn Bộ Tệp Với `cat`

Lệnh `cat` (**Concatenate**) in toàn bộ nội dung của tệp ra màn hình:

```bash
cat /root/ecommerce-app/configs/app.conf
```{{exec}}

### Mẹo hữu ích: Đánh số dòng với `-n`
Cờ `-n` giúp bạn đánh số thứ tự từng dòng, rất thuận tiện khi trao đổi với đồng đội về vị trí dòng bị lỗi trong file code hoặc file cấu hình:

```bash
cat -n /root/ecommerce-app/src/api/server.js
```{{exec}}

> **Lưu ý:** Tránh dùng `cat` cho những tệp log dung lượng lớn hàng trăm Megabyte, vì nó sẽ in ồ ạt làm tràn bộ nhớ đệm của terminal!

---

## 2. Đọc Tệp Lớn Theo Từng Trang Với `less`

Khi cần kiểm tra một tệp văn bản dài, `less` là công cụ tối ưu nhất vì nó tải dữ liệu theo từng trang mà không load toàn bộ tệp vào RAM.

Hãy thử mở tệp log hệ thống của ứng dụng:

```bash
less /var/log/myapp/service.log
```{{exec}}

### Các phím tắt điều hướng quan trọng trong `less`:
- **`Phím cách (Space)` hoặc `Page Down`:** Cuộn tiến một trang.
- **`b` hoặc `Page Up`:** Cuộn lùi lại một trang.
- **`G` (G viết hoa):** Nhảy thẳng xuống dòng cuối cùng của tệp.
- **`g` (g viết thường):** Nhảy về dòng đầu tiên của tệp.
- **`/từ_khóa`:** Tìm kiếm từ khóa (ví dụ: gõ `/ERROR` rồi nhấn Enter để tìm các lỗi, nhấn tiếp phím `n` để nhảy đến kết quả tiếp theo).
- **`q`:** Thoát khỏi màn hình xem `less` và quay lại dòng lệnh terminal.

---

## 3. Trích Xuất Dòng Đầu Với `head` & Dòng Cuối Với `tail`

Thay vì mở toàn bộ tệp, bạn có thể xem nhanh phần đầu hoặc phần cuối tệp tin:

### 3.1. Lệnh `head`
Mặc định in ra 10 dòng đầu tiên. Sử dụng cờ `-n <số_dòng>` để tùy chỉnh:

```bash
# Xem 3 dòng đầu tiên của file log
head -n 3 /var/log/myapp/service.log
```{{exec}}

### 3.2. Lệnh `tail`
Mặc định in ra 10 dòng cuối cùng (thường là những sự kiện log mới nhất vừa xảy ra):

```bash
# Xem 3 dòng cuối cùng của file log
tail -n 3 /var/log/myapp/service.log
```{{exec}}

---

## 4. Theo Dõi Log Thời Gian Thực Với `tail -f`

Trong môi trường Production, khi một tiến trình ứng dụng đang chạy, nó sẽ liên tục ghi các dòng log mới vào tệp. Kỹ sư DevOps sử dụng lệnh:

```bash
tail -f /var/log/myapp/service.log
```{{exec}}

Lệnh này sẽ giữ kết nối mở và in ngay lập tức bất kỳ dòng log nào vừa phát sinh lên màn hình.
Để dừng chế độ theo dõi và quay lại terminal, hãy bấm tổ hợp phím **`Ctrl + C`**.

---

## 5. Đếm Dòng Với `wc -l`

Lệnh `wc` (**Word Count**) dùng để đếm số dòng, số từ hoặc số ký tự. Cờ `-l` (Lines) được dùng phổ biến nhất để kiểm tra số lượng dòng dữ liệu:

```bash
wc -l /var/log/myapp/service.log
```{{exec}}

---

## 6. Thử Thách Bước 3: Phân Tích Nhật Ký Dịch Vụ Ứng Dụng

**Bối cảnh:**
Hệ thống đã chuẩn bị sẵn một tệp nhật ký ứng dụng mẫu tại `/var/log/myapp/service.log` gồm 50 dòng ghi nhận các yêu cầu HTTP và cảnh báo hệ thống.

**Nhiệm vụ của bạn:**
Hãy tạo một tệp báo cáo tổng hợp tại đường dẫn `/tmp/log-analysis.txt` gồm đúng **10 dòng**: 5 dòng đầu tiên và 5 dòng cuối cùng của tệp log.

**Các bước thực hiện:**
1. Dùng lệnh `head -n 5` trích xuất 5 dòng đầu tiên của `/var/log/myapp/service.log` và ghi vào `/tmp/log-analysis.txt` bằng toán tử `>`:
   ```bash
   head -n 5 /var/log/myapp/service.log > /tmp/log-analysis.txt
   ```
2. Dùng lệnh `tail -n 5` trích xuất 5 dòng cuối cùng của `/var/log/myapp/service.log` và ghi nối tiếp vào `/tmp/log-analysis.txt` bằng toán tử `>>`:
   ```bash
   tail -n 5 /var/log/myapp/service.log >> /tmp/log-analysis.txt
   ```
3. Kiểm tra lại tệp báo cáo bằng lệnh `cat -n /tmp/log-analysis.txt` và `wc -l /tmp/log-analysis.txt` để đảm bảo tệp có đúng 10 dòng dữ liệu.

Sau khi hoàn thành, hãy bấm **Check** để hệ thống tự động kiểm tra và hoàn tất bài thực hành!
