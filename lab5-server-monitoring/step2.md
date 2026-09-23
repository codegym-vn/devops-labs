# Bước 2: Logic Cảnh Báo Ngưỡng & Tích Hợp Webhook Alerting

Chỉ in số liệu ra màn hình là chưa đủ. Một hệ thống giám sát thực chiến cần có khả năng **tự động đánh giá số liệu theo các ngưỡng an toàn (Thresholds)** và chủ động gửi thông báo (Alerting) tới kênh liên lạc của đội ngũ kỹ thuật thông qua **Webhook**.

---

## 1. Xác Định Các Mức Độ Cảnh Báo (Severity Levels)

Trong vận hành DevOps tiêu chuẩn, cảnh báo thường được phân cấp:

| Mức Độ | Ngưỡng Tải | Ý Nghĩa | Hành Động |
|---|---|---|---|
| **OK** | Dưới 70% | Hệ thống hoạt động bình thường, an toàn | Không cần gửi cảnh báo |
| **WARNING** | 70% – 84% | Tải tăng cao bất thường hoặc có dấu hiệu rò rỉ | Cảnh báo sớm để kỹ sư chú ý theo dõi |
| **CRITICAL** | Từ 85% trở lên | Hệ thống tiệm cận ngưỡng quá tải, nguy cơ sập dịch vụ | Bắn cảnh báo khẩn cấp, yêu cầu can thiệp ngay |

---

## 2. Kỹ Thuật So Sánh Số Thực Trong Bash

Shell Bash mặc định chỉ hỗ trợ số nguyên (integers). Các chỉ số CPU hay RAM thường có phần thập phân (ví dụ: `72.5`). Để so sánh số thực, chúng ta sử dụng tiện ích `bc` (Basic Calculator):

```bash
VAL=75.4
THRESHOLD=70.0

if [ $(echo "$VAL >= $THRESHOLD" | bc) -eq 1 ]; then
    echo "Gia tri $VAL vuot nguong $THRESHOLD!"
fi
```{{exec}}

Biểu thức `echo "$VAL >= $THRESHOLD" | bc` trả về:
- `1` nếu điều kiện đúng (True).
- `0` nếu điều kiện sai (False).

---

## 3. Thu Thập Ngữ Cảnh Điều Tra (Investigation Context)

Khi nhận được cảnh báo lúc nửa đêm, kỹ sư trực hệ thống cần biết ngay: *Máy chủ nào? IP nào? Sự cố xảy ra lúc nào? Tiến trình nào đang ngốn tài nguyên nhất?*

Các lệnh thu thập ngữ cảnh nhanh:
- **Tên máy chủ**: `hostname`
- **Địa chỉ IP**: `hostname -I | awk '{print $1}'`
- **Thời gian**: `date '+%Y-%m-%d %H:%M:%S'`
- **Top tiến trình chiếm CPU/RAM nhất**:
  ```bash
  ps aux --sort=-%cpu | head -4 | awk '{printf "%s (PID: %s, CPU: %s%%)\n", $11, $2, $3}'
  ```{{exec}}

---

## 4. Đóng Gói Thông Điệp Cảnh Báo Dạng JSON

Dữ liệu gửi qua Webhook thường được chuẩn hóa dưới dạng JSON để các hệ thống nhận (Slack, Discord, Telegram, PagerDuty) có thể bóc tách dễ dàng:

```bash
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

PAYLOAD=$(cat << EOF
{
  "hostname": "$HOSTNAME",
  "ip": "$IP",
  "timestamp": "$TIMESTAMP",
  "metric": "RAM",
  "value": 86.5,
  "severity": "CRITICAL",
  "message": "RAM usage exceeded critical threshold (85%)"
}
EOF
)
```

---

## 5. Gửi Cảnh Báo Qua Webhook Bằng `curl`

Chúng ta sử dụng lệnh `curl` với phương thức `POST`, header `Content-Type: application/json` và kèm theo payload JSON:

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"metric":"TEST","value":99,"severity":"INFO","message":"Test alert connection"}' \
  http://127.0.0.1:9090/webhook
```{{exec}}

Kiểm tra nhật ký tại dịch vụ nhận cảnh báo:

```bash
tail -n 5 /var/log/alerts.log
```{{exec}}

Bạn sẽ thấy bản ghi cảnh báo kèm timestamp được ghi nhận vào log file.

> **Mở rộng trong thực tế:**
> - **Telegram**: Gửi tới `https://api.telegram.org/bot<TOKEN>/sendMessage -d chat_id=<ID> -d text="<MESSAGE>"`.
> - **Discord**: Gửi JSON `{"content": "<MESSAGE>"}` tới Webhook URL của channel.
> - **Slack**: Gửi JSON `{"text": "<MESSAGE>"}` tới Incoming Webhook URL.

---

## 6. Cơ Chế Chống Bão Cảnh Báo (Alert Fatigue & Cooldown)

Nếu script chạy mỗi phút một lần và sự cố CPU kéo dài 60 phút, hệ thống sẽ gửi 60 tin nhắn liên tục, gây "ngợp cảnh báo" (alert fatigue).

Để khắc phục, ta sử dụng một **file khóa tạm thời (cooldown lock file)**:
- Khi phát hiện vượt ngưỡng, kiểm tra xem file `/tmp/alert_<metric>.lock` đã tồn tại chưa.
- Nếu file lock chưa có (hoặc đã tạo cách đây hơn 15 phút), gửi cảnh báo và tạo file lock: `touch /tmp/alert_<metric>.lock`.
- Nếu trạng thái đã trở về mức OK (< 70%), xóa file lock để sẵn sàng cho lần cảnh báo tiếp theo: `rm -f /tmp/alert_<metric>.lock`.

---

## 7. Thử Thách & Xác Thực (Verification)

Nâng cấp script `/root/monitor.sh` để tích hợp logic cảnh báo ngưỡng và gửi webhook:

### Yêu cầu thử thách:
1. Mở file `/root/monitor.sh` và bổ sung cấu hình:
   - Biến `WEBHOOK_URL="http://127.0.0.1:9090/webhook"`.
   - Các ngưỡng: `WARN_THRESHOLD=70` và `CRIT_THRESHOLD=85`.
2. Viết hàm `send_alert()` nhận các tham số: tên chỉ số (`metric`), giá trị đo được (`value`), và mức độ (`severity`).
3. Đóng gói payload JSON chứa tối thiểu các trường: `hostname`, `metric`, `value`, `severity` và dùng `curl` POST tới `WEBHOOK_URL`.
4. Trong script, bổ sung đoạn mã kiểm tra:
   - Nếu chỉ số >= `CRIT_THRESHOLD` (85%), gửi cảnh báo `CRITICAL`.
   - Nếu chỉ số >= `WARN_THRESHOLD` (70%) và < 85%, gửi cảnh báo `WARNING`.
5. **Kích hoạt gửi cảnh báo thử nghiệm**: Để kiểm chứng kết nối webhook ngay lập tức, hãy thêm một lệnh gọi hàm `send_alert` gửi một cảnh báo mẫu (ví dụ: metric `RAM`, severity `WARNING` hoặc `TEST`) tới webhook.
6. Chạy script `/root/monitor.sh` và dùng lệnh `cat /var/log/alerts.log` để xác nhận cảnh báo đã được gửi và ghi nhận thành công.

*(Lưu ý: Bạn phải tự nhập lệnh, không có nút chạy tự động cho phần thử thách)*

<details>
<summary>Xem gợi ý mã mẫu hoàn chỉnh</summary>

```bash
cat << 'EOF' > /root/monitor.sh
#!/bin/bash

WEBHOOK_URL="http://127.0.0.1:9090/webhook"
WARN_THRESHOLD=70
CRIT_THRESHOLD=85

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{for(i=1;i<=NF;i++) if($i ~ /id/) {gsub(/[^0-9.]/,"",$(i-1)); printf "%.1f", 100 - $(i-1)}}'
}

get_ram_usage() {
    free -m | awk '/Mem:/ {printf "%.1f", ($3/$2) * 100}'
}

get_disk_usage() {
    df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

send_alert() {
    local metric="$1"
    local value="$2"
    local severity="$3"
    local hostname="$(hostname)"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    local payload=$(cat << JSON
{
  "hostname": "$hostname",
  "timestamp": "$timestamp",
  "metric": "$metric",
  "value": $value,
  "severity": "$severity"
}
JSON
    )

    curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" > /dev/null
}

check_metric() {
    local metric="$1"
    local value="$2"

    if [ $(echo "$value >= $CRIT_THRESHOLD" | bc) -eq 1 ]; then
        send_alert "$metric" "$value" "CRITICAL"
    elif [ $(echo "$value >= $WARN_THRESHOLD" | bc) -eq 1 ]; then
        send_alert "$metric" "$value" "WARNING"
    fi
}

CPU=$(get_cpu_usage)
RAM=$(get_ram_usage)
DISK=$(get_disk_usage)

echo "CPU: ${CPU}% | RAM: ${RAM}% | DISK: ${DISK}%"

# Kiem tra cac chi so
check_metric "CPU" "$CPU"
check_metric "RAM" "$RAM"
check_metric "DISK" "$DISK"

# Gui mot canh bao khoi tao mau de xac nhan webhook
send_alert "SYSTEM" "0" "INFO"
EOF

chmod +x /root/monitor.sh
/root/monitor.sh
cat /var/log/alerts.log
```

</details>

Sau khi hoàn thành và thấy bản ghi cảnh báo trong `/var/log/alerts.log`, hãy bấm nút **Check** bên dưới để hệ thống tự động xác thực!
