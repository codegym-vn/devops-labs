# Bước 2: Cấu Hình Alertmanager & Định Tuyến Cảnh Báo (Routing)

Sau khi Prometheus phát hiện sự cố và chuyển trạng thái Alert thành `Firing`, nó sẽ gửi một yêu cầu HTTP POST chứa toàn bộ danh sách cảnh báo sang **Alertmanager**.

Nhiệm vụ của Alertmanager là **chống trùng lặp (Deduplication)**, **gom cụm (Grouping)** và **định tuyến (Routing)** cảnh báo đến đúng người nhận (Receivers).

---

### 1. Cơ Chế Gom Nhóm Cảnh Báo (Alert Grouping)

Nếu một sự cố nghiêm trọng xảy ra (ví dụ: sập Switch mạng hoặc sập Database), hàng chục hoặc hàng trăm cảnh báo con có thể bùng phát trong vòng vài giây.

Alertmanager sử dụng 4 tham số vàng để kiểm soát việc gom nhóm:

| Tham số | Ý nghĩa kỹ thuật | Khuyến nghị Production |
| :--- | :--- | :--- |
| **`group_by`** | Tập hợp các nhãn dùng để nhóm các alert lại với nhau (ví dụ: `['alertname', 'service']`). Các alert có cùng giá trị của những nhãn này sẽ được gói chung vào **1 email / 1 tin nhắn duy nhất**. | Gom theo `['alertname', 'cluster', 'service']` |
| **`group_wait`** | Thời gian chờ ban đầu để thu thập các alert cùng nhóm trước khi phát thông báo đầu tiên. | `5s` đến `30s` |
| **`group_interval`** | Sau khi thông báo đầu tiên đã gửi, nếu xuất hiện thêm alert mới thuộc nhóm này, khoảng thời gian chờ để gửi tin nhắn cập nhật. | `10s` đến `5m` |
| **`repeat_interval`** | Thời gian nhắc lại thông báo nếu sự cố vẫn tiếp tục kéo dài mà chưa được giải quyết (Resolved). | `1h` đến `4h` (tránh spam) |

---

### 2. Thiết Kế Cây Định Tuyến Cảnh Báo (Routing Tree)

Khởi tạo tệp cấu hình nâng cao `/root/alerting-lab/alertmanager.yml`:

```bash
cat << 'EOF' > /root/alerting-lab/alertmanager.yml
global:
  resolve_timeout: 1m

route:
  group_by: ['alertname', 'service', 'tier']
  group_wait: 5s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default-webhook'

  routes:
    - match:
        severity: critical
      receiver: 'critical-webhook'
      continue: false

receivers:
  - name: 'default-webhook'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

  - name: 'critical-webhook'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true
EOF
```

**Giải thích:**
- **`continue: false`**: Khi một cảnh báo khớp với nhánh `severity: critical`, nó sẽ được gửi tới `critical-webhook` và dừng lại ngay tại nhánh này, không rơi tiếp xuống các nhánh bên dưới.
- **`send_resolved: true`**: Khi sự cố kết thúc (trở về bình thường), Alertmanager sẽ tự động gửi thêm một thông báo trạng thái `Resolved` để thông báo cho đội ngũ kỹ thuật biết hệ thống đã phục hồi.

---

### 3. Kiểm Thử Cấu Hình Bằng `amtool` & Nạp Cấu Hình

Tương tự như `promtool` của Prometheus, Alertmanager cung cấp công cụ dòng lệnh **`amtool`** để kiểm tra tính hợp lệ của tệp cấu hình trước khi nạp vào dịch vụ:

```bash
# Kiểm tra cú pháp alertmanager.yml
amtool check-config /root/alerting-lab/alertmanager.yml
```

Nếu kết quả trả về `SUCCESS`, khởi động lại hoặc kích hoạt reload Alertmanager:

```bash
# Reload cấu hình Alertmanager
curl -s -X POST http://localhost:9093/-/reload

# Hoặc khởi động lại nhẹ container
docker restart alertmanager
sleep 2
```

---

### 4. Kiểm Tra Kết Nối Prometheus Đến Alertmanager

Xác thực xem Prometheus đã nhận diện và kết nối thông suốt tới Alertmanager trên cổng `9093` hay chưa:

```bash
curl -s http://localhost:9090/api/v1/alertmanagers | jq .data.activeAlertmanagers
```

Kết quả trả về sẽ hiển thị URL kết nối: `http://localhost:9093/api/v2/alerts`.

Bạn cũng có thể mở trình duyệt truy cập:
* `http://localhost:9093/#/status`: Xem chi tiết cây định tuyến (Routing Tree), cấu hình Global và danh sách các Receivers đã được kích hoạt.

---

### 5. Yêu Cầu Hoàn Thành Bước 2

1. Tệp `/root/alerting-lab/alertmanager.yml` được cấu hình đầy đủ `group_by`, `routes` và `receivers`, vượt qua kiểm tra của `amtool`.
2. Prometheus API `/api/v1/alertmanagers` trả về ít nhất 1 `activeAlertmanager` đang hoạt động tốt.

Sau khi hoàn tất, nhấn **Check** để hệ thống tự động kiểm tra Bước 2.
