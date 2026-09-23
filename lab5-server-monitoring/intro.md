# Chào Mừng Đến Với Lab 5: Giám Sát Tài Nguyên Máy Chủ & Cảnh Báo Tự Động Với Bash Script

Trong quản trị hạ tầng hệ thống và vận hành DevOps, việc **giám sát liên tục trạng thái máy chủ** (Server Monitoring) là tuyến phòng thủ đầu tiên giúp phát hiện sớm sự cố quá tải, rò rỉ bộ nhớ (memory leak) hoặc tràn dung lượng ổ đĩa trước khi dịch vụ bị gián đoạn.

Dù hiện nay có nhiều nền tảng giám sát phân tán hiện đại như Prometheus, Grafana, Datadog hay Zabbix, kỹ năng viết **Bash Script giám sát tự động** vẫn là nền tảng sống còn của mọi kỹ sư DevOps bởi:
- **Độc lập và gọn nhẹ (Agentless & Zero-dependency)**: Chạy trực tiếp trên bất kỳ máy chủ Linux nào mà không cần cài đặt agent nặng nề hay trả phí bản quyền.
- **Tùy biến cao (Customizable)**: Dễ dàng kiểm tra bất kỳ chỉ số nghiệp vụ đặc thù nào (tiến trình, file, port, network socket).
- **Phản ứng tức thì (Self-healing & Alerting)**: Có thể tự động kích hoạt khởi động lại dịch vụ hoặc bắn cảnh báo tức thì vào kênh chat của đội ngũ kỹ thuật.

---

## Kiến Trúc Hệ Thống Giám Sát Trong Bài Lab

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Linux Server (Ubuntu Node)                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  1. Thu thập số liệu (Metrics Collection)                              │
│     ├── CPU Usage       : top /proc/stat                               │
│     ├── RAM Usage       : free -m                                      │
│     └── Disk Usage      : df -h /                                      │
│                                                                        │
│  2. Đánh giá ngưỡng (Threshold Evaluation)                             │
│     ├── WARNING  : >= 70%                                              │
│     └── CRITICAL : >= 85%                                              │
│                                                                        │
│  3. Đóng gói & Gửi cảnh báo (Alert Payload & Dispatch)                │
│     ├── JSON Payload: Hostname, IP, Timestamp, Metric, Value, Severity │
│     └── Webhook Dispatch qua curl POST                                 │
│                                                                        │
│  4. Tự động hóa định kỳ (Scheduled Automation)                         │
│     └── Crontab (* * * * * /usr/local/bin/monitor.sh)                  │
│                                                                        │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ HTTP POST (Webhook)
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         Alert Webhook Receiver                         │
│  ├── Local Endpoint   : http://127.0.0.1:9090/webhook (/var/log/alerts)│
│  └── Hoặc External    : Telegram Bot / Discord / Slack Channel         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Lộ Trình 3 Bước Thực Hành

| Bước | Chủ Đề | Nội Dung Chi Tiết |
|---|---|---|
| **Bước 1** | **Thu Thập & Bóc Tách Chỉ Số** | Dùng các lệnh Linux (`free`, `df`, `top`), kết hợp `awk` và `bc` để trích xuất tỷ lệ phần trăm sử dụng của CPU, RAM và Disk. |
| **Bước 2** | **Logic Ngưỡng & Bắn Webhook** | Xây dựng logic so sánh ngưỡng WARNING/CRITICAL, định dạng gói tin JSON và gửi cảnh báo bằng `curl` tới webhook endpoint. |
| **Bước 3** | **Lập Lịch Crontab & Stress Test** | Cấu hình Crontab chạy script tự động mỗi phút, sử dụng công cụ `stress-ng` để tạo tải nhân tạo và kiểm chứng cảnh báo được kích hoạt tự động. |

---

## Yêu Cầu Về Môi Trường & Lưu Ý Thực Hành

- Môi trường đã được cài đặt sẵn các tiện ích: `bc`, `jq`, `stress-ng`, `curl`.
- Một dịch vụ **Local Alert Receiver** đã được kích hoạt chạy nền trên cổng `9090` để nhận các request cảnh báo từ script của bạn và ghi nhật ký vào `/var/log/alerts.log`.
- Toàn bộ các thử thách ở cuối mỗi bước được thiết kế theo dạng **DIY (Do It Yourself)**: bạn cần tự tay gõ lệnh và viết mã vào file script để rèn luyện kỹ năng thực chiến.

Nhấn **Start Scenario** để bắt đầu Bước 1!
