# Bước 4: Mô Phỏng Sự Cố Hệ Thống & Kiểm Chứng Luồng Firing / Resolved

Để kiểm chứng toàn bộ chuỗi mắt xích cảnh báo hoạt động hoàn hảo, trong bước này bạn sẽ đóng vai trò SRE thực chiến: **kích hoạt sự cố thực tế (Fault Injection)**, quan sát chu trình chuyển dịch trạng thái của Alert, kiểm tra gói tin Webhook và xác nhận thông báo phục hồi (`Resolved`).

---

### 1. Kích Hoạt Sự Cố Giả Lập: Lỗi 500 Hàng Loạt Trên Ecommerce API

Ứng dụng mẫu đã được tích hợp sẵn cổng kích hoạt lỗi. Gọi endpoint mô phỏng lỗi thanh toán trên toàn hệ thống:

```bash
# 1. Kích hoạt chế độ lỗi (Error Mode)
curl -s -X POST http://localhost:8080/simulate/errors | jq .

# 2. Bắn một loạt 20 request POST vào /api/orders để tăng vọt tỷ lệ 5xx
for i in {1..20}; do
  curl -s -X POST http://localhost:8080/api/orders -H "Content-Type: application/json" -d '{"amount":99}' > /dev/null &
done
```

---

### 2. Quan Sát Chu Trình Cảnh Báo (Pending -> Firing)

Sau khi kích hoạt lỗi, hãy chờ khoảng 15 đến 20 giây (bằng thời gian `for: 15s` đã cấu hình ở Bước 1) và kiểm tra trạng thái cảnh báo trên Prometheus:

```bash
# Kiểm tra trạng thái Alert trên Prometheus
curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | {alertname: .labels.alertname, state: .state, value: .value}'
```

Bạn sẽ thấy cảnh báo **`ApiHighErrorRate`** chuyển từ `pending` sang `firing`!

Kiểm tra trực tiếp trên Alertmanager bằng công cụ dòng lệnh `amtool`:

```bash
amtool alert query
```

---

### 3. Kiểm Tra Gói Tin Nhận Được Tại Webhook Receiver

Khi Alertmanager nhận được alert ở trạng thái `firing`, nó sẽ gom nhóm và gửi gói tin JSON qua HTTP POST tới Webhook Receiver (`port 5001`).

Xem nội dung nhật ký Webhook đã tiếp nhận:

```bash
cat /root/alerting-lab/webhook.log
```

Xem toàn bộ cấu trúc JSON chuẩn mà Alertmanager đã bắn ra tại tệp `/root/alerting-lab/latest-alert.json`:

```bash
cat /root/alerting-lab/latest-alert.json | jq '{status: .status, receiver: .receiver, alerts: [.alerts[] | {alertname: .labels.alertname, status: .status, summary: .annotations.summary}]}'
```

---

### 4. Khắc Phục Sự Cố & Xác Thực Thông Báo Phục Hồi (Resolved)

Sau khi đội ngũ kỹ thuật can thiệp, hãy gọi lệnh phục hồi trạng thái hoạt động bình thường cho ứng dụng:

```bash
# Khôi phục hệ thống về trạng thái bình thường
curl -s -X POST http://localhost:8080/simulate/recover | jq .
```

Sau khoảng 15 giây, khi tỷ lệ lỗi 5xx giảm về 0, Prometheus sẽ nhận thấy điều kiện không còn vi phạm và gửi tín hiệu phục hồi sang Alertmanager. Alertmanager sẽ gửi ngay một thông báo với `status: "resolved"`.

Kiểm tra lại tệp log để xác nhận tín hiệu phục hồi:

```bash
cat /root/alerting-lab/webhook.log
```

Bạn sẽ thấy xuất hiện thêm dòng thông báo:
```text
[...] RECEIVED WEBHOOK ALERT (Status: resolved, Count: 1)
  - Alert: ApiHighErrorRate | Severity: critical | Status: resolved
```

---

### 5. Xuất Bản Báo Cáo Sự Cố & Hoàn Thành Bước 4

Tạo tệp báo cáo tổng kết quy trình kiểm chứng cảnh báo tại `/root/alerting-lab/alert-incident-report.json`:

```bash
cat << 'EOF' > /root/alerting-lab/alert-incident-report.json
{
  "incident": "INC-API-5XX-SPIKE",
  "alertname": "ApiHighErrorRate",
  "severity": "critical",
  "verification": {
    "prometheus_evaluated": true,
    "alertmanager_routed": true,
    "webhook_firing_received": true,
    "webhook_resolved_received": true
  },
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
cat /root/alerting-lab/alert-incident-report.json
```

Sau khi tạo xong tệp báo cáo, nhấn **Check** để hệ thống tự động đánh giá toàn bộ quy trình kiểm chứng Firing và Resolved của bạn!
