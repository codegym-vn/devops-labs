# Bước 2: Cơ Chế Đường Ống Pipe & Xử Lý Dữ Liệu Chuỗi

Toán tử đường ống **Pipe (`|`)** là một trong những phát minh quan trọng nhất của hệ điều hành Unix, cho phép kết nối nhiều công cụ đơn lẻ thành một dây chuyền xử lý dữ liệu tự động và mạnh mẽ.

---

## 1. Cơ Chế Vận Hành Của Đường Ống (Pipe `|`)

Khi bạn sử dụng dấu gạch đứng `|`:

```text
Lệnh_A  |  Lệnh_B  |  Lệnh_C
```

Hệ điều hành sẽ lấy toàn bộ luồng kết quả xuất chuẩn `stdout` của `Lệnh_A` và bơm trực tiếp làm đầu vào `stdin` cho `Lệnh_B` thông qua bộ nhớ đệm (RAM buffer). Quá trình này diễn ra hoàn toàn tức thì mà không cần tốn thời gian ghi bất kỳ tệp tạm nào ra ổ cứng.

---

## 2. Bộ Lọc Văn Bản Kinh Điển Trong DevOps

Khi kết hợp với đường ống, các lệnh sau đây trở thành "vũ khí" đắc lực để xử lý log và dữ liệu:

- **`grep <từ_khóa>`:** Lọc và chỉ giữ lại những dòng có chứa từ khóa.
- **`wc -l`:** Đếm tổng số dòng nhận được từ luồng trước.
- **`sort`:** Sắp xếp các dòng văn bản theo thứ tự bảng chữ cái hoặc số học (`-n` số học, `-r` đảo ngược).
- **`uniq`:** Loại bỏ các dòng trùng lặp liền kề (`-c` đếm số lần xuất hiện của từng dòng).
- **`tee <tệp_tin>`:** Đóng vai trò như một cút nối ngã ba: vừa ghi dữ liệu ra một tệp tin trên ổ cứng, vừa cho phép dòng dữ liệu tiếp tục chảy sang lệnh tiếp theo trên đường ống.

### Ví dụ chuỗi đường ống thực tế:
```bash
# Đếm số lượng tiến trình đang chạy trong hệ thống
ps aux | wc -l

# Lọc danh sách tiến trình của root và đếm
ps aux | grep root | wc -l
```{{exec}}

---

## 3. Khảo Sát Tệp Bản Ghi Máy Chủ Nginx

Hệ thống đã chuẩn bị sẵn một tệp nhật ký truy cập web mẫu tại `/var/log/nginx/access.log`. Hãy quan sát một vài dòng:

```bash
head -n 5 /var/log/nginx/access.log
```{{exec}}

Mỗi dòng nhật ký chứa địa chỉ IP, thời gian, phương thức HTTP, đường dẫn và mã phản hồi trạng thái HTTP (ví dụ: `200` thành công, `404` không tìm thấy trang, `500` lỗi máy chủ nội bộ).

---

## 4. Thử Thách Bước 2: Xây Dựng Pipeline Phân Tích Lỗi Web

**Nhiệm vụ của bạn:**
Hãy xây dựng một chuỗi đường ống để xử lý tệp `/var/log/nginx/access.log` với các yêu cầu sau:

1. Lọc tất cả các yêu cầu phát sinh mã lỗi `404` hoặc `500`.
2. Dùng lệnh `tee` để lưu danh sách các dòng lỗi này vào tệp `/tmp/filtered-errors.log`.
3. Tiếp tục dẫn luồng dữ liệu qua lệnh `wc -l` để đếm tổng số lượng lỗi và lưu con số này vào tệp `/tmp/error-count.txt`.

> **Gợi ý thực hiện bằng một dòng lệnh duy nhất:**
> ```bash
> grep -E " (404|500) " /var/log/nginx/access.log | tee /tmp/filtered-errors.log | wc -l > /tmp/error-count.txt
> ```
> Sau đó hãy kiểm tra lại kết quả:
> - `cat /tmp/error-count.txt` (sẽ hiển thị con số 12)
> - `cat /tmp/filtered-errors.log`

Sau khi hoàn tất, hãy nhấn nút **Check** để hệ thống tự động kiểm tra pipeline của bạn!
