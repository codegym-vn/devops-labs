# Chúc Mừng Bạn Đã Hoàn Thành Lab 5!

Bạn đã xây dựng thành công một **Hệ Thống Giám Sát Tài Nguyên Máy Chủ & Cảnh Báo Tự Động Bằng Bash Script** hoàn chỉnh từ đầu — một kỹ năng cốt lõi và cực kỳ giá trị trong quản trị hệ thống Linux và vận hành DevOps thực chiến.

---

## Bảng Tra Cứu Nhanh Lệnh Giám Sát Linux (DevOps Monitoring Cheat Sheet)

### 1. Thu Thập Số Liệu Tài Nguyên

| Mục Đích | Lệnh Thực Hiện | Giải Thích |
|---|---|---|
| **RAM sử dụng (MB)** | `free -m` | Xem bộ nhớ vật lý, swap, cache và dung lượng khả dụng |
| **Tính % RAM đã dùng** | `free -m \| awk '/Mem:/ {printf "%.1f", ($3/$2)*100}'` | Lấy `used / total * 100` |
| **Dung lượng đĩa gốc** | `df -P / \| awk 'NR==2 {gsub("%","",$5); print $5}'` | Lấy tỷ lệ % dung lượng phân vùng `/` |
| **CPU sử dụng (%)** | `top -bn1 \| grep "Cpu(s)"` | Lấy thông số idle và tính `100 - idle` |
| **Tải trung bình hệ thống** | `cat /proc/loadavg` | Xem load average trong 1, 5 và 15 phút gần nhất |
| **Top tiến trình ngốn CPU** | `ps aux --sort=-%cpu \| head -5` | Liệt kê tiến trình tiêu thụ nhiều CPU nhất |
| **Top tiến trình ngốn RAM** | `ps aux --sort=-%mem \| head -5` | Liệt kê tiến trình tiêu thụ nhiều RAM nhất |

### 2. Tự Động Hóa & Webhook

| Mục Đích | Lệnh / Cấu Hình |
|---|---|
| **Gửi Webhook JSON** | `curl -s -X POST -H "Content-Type: application/json" -d '<JSON>' <URL>` |
| **So sánh số thực trong Bash** | `if [ $(echo "$VAL >= $THRESH" \| bc) -eq 1 ]; then ... fi` |
| **Xem crontab của user** | `crontab -l` |
| **Thêm cronjob tự động** | `(crontab -l; echo "* * * * * /path/to/script.sh") \| crontab -` |
| **Xem log cảnh báo** | `tail -f /var/log/alerts.log` |
| **Kiểm tra cú pháp script** | `bash -n /path/to/script.sh` |

---

## Checklist Tự Đánh Giá Năng Lực

- [x] Bóc tách chính xác tỷ lệ sử dụng của RAM (`free`), Disk (`df`) và CPU (`top`) bằng lệnh dòng lệnh và `awk`.
- [x] Hiểu và thực hiện được phép so sánh số thực trong Bash script bằng tiện ích `bc`.
- [x] Thu thập ngữ cảnh điều tra sự cố (Hostname, IP, Timestamp, Top Processes).
- [x] Đóng gói dữ liệu cảnh báo có cấu trúc theo định dạng chuẩn JSON.
- [x] Sử dụng `curl` để phát cảnh báo tự động qua HTTP POST Webhook.
- [x] Hiểu cơ chế chống bão cảnh báo (Alert Fatigue / Cooldown Lock).
- [x] Lập lịch định kỳ bằng Crontab để giám sát liên tục không cần con người can thiệp.
- [x] Sử dụng thành thạo công cụ `stress-ng` để kiểm thử khả năng chịu tải và tính chính xác của hệ thống cảnh báo.

---

## Bước Tiếp Theo Trong Hành Trình DevOps

Bài lab này đã giúp bạn nắm vững tư duy giám sát từ tầng thấp nhất (OS metrics, thresholding, webhook alerting). Với nền tảng này, bạn đã sẵn sàng tiến lên các công nghệ giám sát và tự động hóa phân tán:
- **Prometheus & Node Exporter**: Thu thập metrics theo mô hình pull-based chuẩn công nghiệp.
- **Grafana**: Xây dựng bảng điều khiển trực quan hóa thời gian thực (Dashboarding).
- **Alertmanager**: Quản lý định tuyến cảnh báo thông minh, gom nhóm (grouping), và dập tắt cảnh báo trùng lặp (silencing).
