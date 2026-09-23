# Bước 3: Lập Lịch Bằng Crontab & Thử Nghiệm Quá Tải Hệ Thống

Sau khi đã hoàn thiện logic giám sát và tích hợp webhook, bước cuối cùng để đưa script vào vận hành thực tế là **tự động hóa định kỳ (Scheduled Automation)** và **kiểm thử quá tải (Stress Testing)** để đảm bảo hệ thống phản ứng chính xác khi xảy ra sự cố thật.

---

## 1. Chuẩn Hóa Vị Trí Script Trong Hệ Thống

Theo tiêu chuẩn phân cấp thư mục Linux (FHS - Filesystem Hierarchy Standard):
- `/root/` hoặc `/home/user/` chỉ dành cho dữ liệu cá nhân của người dùng.
- `/usr/local/bin/` là nơi chuẩn hóa để đặt các công cụ, script quản trị hệ thống do quản trị viên tự phát triển.

Di chuyển và cấp quyền cho script:

```bash
cp /root/monitor.sh /usr/local/bin/monitor.sh
chmod +x /usr/local/bin/monitor.sh
```{{exec}}

---

## 2. Tự Động Hóa Định Kỳ Bằng Crontab

`cron` là daemon lập lịch tác vụ chạy nền trên hệ điều hành Linux. Cấu trúc một dòng lệnh trong Crontab gồm 5 trường thời gian:

```text
┌───────────── Phút (0 - 59)
│ ┌─────────── Giờ (0 - 23)
│ │ ┌───────── Ngày trong tháng (1 - 31)
│ │ │ ┌─────── Tháng (1 - 12)
│ │ │ │ ┌───── Ngày trong tuần (0 - 6, 0 = Chủ Nhật)
│ │ │ │ │
* * * * * <lệnh_cần_thực_thi>
```

### Thiết lập chạy script mỗi 1 phút một lần

Trong quản trị máy chủ, chu kỳ 1 phút là chu kỳ phổ biến để lấy mẫu tài nguyên và phát hiện sớm sự cố:

```text
* * * * * /usr/local/bin/monitor.sh >> /var/log/monitor.log 2>&1
```

- `>> /var/log/monitor.log`: Ghi nối tiếp đầu ra chuẩn (stdout) vào log file để theo dõi lịch sử.
- `2>&1`: Điều hướng cả lỗi (stderr) vào cùng file log để thuận tiện debug khi script gặp sự cố.

### Thao tác với Crontab:
- `crontab -e`: Mở trình soạn thảo để chỉnh sửa crontab của user hiện tại.
- `crontab -l`: Liệt kê danh sách các tác vụ cron đang hoạt động.
- `crontab -r`: Xóa toàn bộ crontab của user.

---

## 3. Thử Nghiệm Quá Tải Hệ Thống Với `stress-ng`

Trong môi trường bình thường, máy chủ chỉ dùng từ 5% đến 20% CPU và RAM. Nếu không có tải cao, bạn không thể chắc chắn logic cảnh báo `CRITICAL` (>= 85%) có hoạt động chính xác hay không.

Công cụ `stress-ng` cho phép tạo tải nhân tạo lên CPU, RAM, I/O theo ý muốn:

### Lệnh tạo tải CPU lên 100%:
```bash
stress-ng --cpu 2 --timeout 20s --metrics-brief
```{{exec}}

Lệnh trên sẽ chiếm dụng 2 core CPU liên tục trong 20 giây và tự động dừng lại.

---

## 4. Kiểm Tra Nhật Ký Giám Sát & Cảnh Báo

Khi hệ thống bị quá tải, script giám sát chạy định kỳ (hoặc chạy thủ công) sẽ phát hiện CPU > 85% và bắn ngay một cảnh báo cấp độ `CRITICAL` tới Webhook:

Xem log thực thi của script:
```bash
cat /var/log/monitor.log 2>/dev/null || echo "Chua co log"
```{{exec}}

Xem log cảnh báo đã nhận:
```bash
cat /var/log/alerts.log
```{{exec}}

---

## 5. Thử Thách & Xác Thực (Verification)

Hãy hoàn thiện quy trình tự động hóa và kiểm thử thực tế cho bài lab:

### Yêu cầu thử thách:
1. Đảm bảo script `/usr/local/bin/monitor.sh` tồn tại và có quyền thực thi (`chmod +x`).
2. Cấu hình Crontab cho root user để chạy `/usr/local/bin/monitor.sh` mỗi phút:
   ```text
   * * * * * /usr/local/bin/monitor.sh >> /var/log/monitor.log 2>&1
   ```
3. Kiểm tra danh sách crontab bằng lệnh `crontab -l` để xác nhận tác vụ đã được nạp.
4. **Kích hoạt cảnh báo CRITICAL**:
   - Chạy công cụ `stress-ng` để đẩy tải CPU lên cao:
     ```bash
     stress-ng --cpu 2 --timeout 30s &
     ```
   - Trong lúc tải đang cao, kích hoạt script `/usr/local/bin/monitor.sh` (hoặc đợi cronjob tự động chạy) để gửi một cảnh báo cấp độ `CRITICAL` tới Webhook.
5. Dùng lệnh `grep "CRITICAL" /var/log/alerts.log` để xác nhận hệ thống đã ghi nhận ít nhất một cảnh báo mức độ `CRITICAL`.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý các bước thực hiện</summary>

Sao chép script và cấp quyền:
```bash
cp /root/monitor.sh /usr/local/bin/monitor.sh
chmod +x /usr/local/bin/monitor.sh
```

Nạp cronjob tự động cho root:
```bash
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/monitor.sh >> /var/log/monitor.log 2>&1") | crontab -
crontab -l
```

Kích hoạt stress test và thực thi script khi tải cao:
```bash
stress-ng --cpu 2 --timeout 25s &
sleep 3
/usr/local/bin/monitor.sh
grep -i "CRITICAL" /var/log/alerts.log
```

</details>

Sau khi hoàn thành và thấy bản ghi `CRITICAL` trong `/var/log/alerts.log`, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
