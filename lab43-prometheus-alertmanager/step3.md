# Bước 3: Cơ Chế Chống Bão Cảnh Báo (Inhibition) & Tắt Tiếng (Silences)

Một kỹ sư SRE giỏi không chỉ biết tạo cảnh báo, mà còn phải biết **ngăn chặn cảnh báo rác**. Trong bước này, bạn sẽ làm chủ 2 vũ khí quan trọng nhất của Alertmanager để đối phó với hiện tượng "Bão cảnh báo" (Alert Fatigue): **Inhibition Rules** và **Silences**.

---

### 1. Cơ Chế Kìm Hãm Cảnh Báo (Inhibition Rules)

**Kịch bản thực tế:** Khi một máy chủ Linux bị sập nguồn hoàn toàn, alert `ServiceTargetDown` (critical) sẽ được kích hoạt. Ngay sau đó, hàng loạt cảnh báo thứ cấp như `HostHighCpuLoad` (warning), `HighDiskLatency` (warning)... cũng có thể bị kích hoạt do mất kết nối.

Nếu không có cơ chế ngăn chặn, đội On-Call sẽ nhận một tràng tin nhắn dồn dập cho cùng một nguyên nhân gốc rễ (Root Cause).

**Inhibition Rule** cho phép bạn định nghĩa: *Nếu một cảnh báo gốc (Source Alert) đang Firing, hãy tự động **kìm hãm (mute)** các cảnh báo thứ cấp (Target Alerts) có cùng nhãn liên quan:*

```yaml
inhibit_rules:
  - source_match:
      alertname: 'ServiceTargetDown'
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['instance']
```

- **`source_match`**: Điều kiện của cảnh báo gốc đang Firing.
- **`target_match`**: Điều kiện của các cảnh báo con sẽ bị chặn lại.
- **`equal`**: Tập hợp các nhãn phải trùng khớp nhau (ví dụ: cùng xảy ra trên `instance: 'srv-prod-01'`).

---

### 2. Cập Nhật Cấu Hình Alertmanager Với Inhibition

Cập nhật tệp `/root/alerting-lab/alertmanager.yml` để bổ sung quy tắc kìm hãm:

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

inhibit_rules:
  - source_match:
      alertname: 'ServiceTargetDown'
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['instance']

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

Nạp lại cấu hình vào Alertmanager:

```bash
amtool check-config /root/alerting-lab/alertmanager.yml
curl -s -X POST http://localhost:9093/-/reload
```

---

### 3. Thiết Lập Tắt Tiếng Bảo Trì (Silences) Bằng `amtool`

**Tình huống:** Đội ngũ hạ tầng dự kiến nâng cấp phiên bản Kernel cho máy chủ `srv-prod-01` trong khung giờ bảo trì (Maintenance Window). Bạn muốn **tắt tiếng tạm thời** các cảnh báo CPU trong 2 giờ để không làm phiền đồng nghiệp đang ngủ, nhưng không muốn xóa bỏ Alert Rule khỏi hệ thống.

Sử dụng lệnh `amtool silence add` để tạo một bản ghi tắt tiếng:

```bash
amtool silence add alertname="HostHighCpuLoad" \
  --duration="2h" \
  --comment="Bao tri nang cap Linux Kernel dinh ky theo ke hoach" \
  --author="sre-team@company.com"
```

Lệnh trên sẽ in ra một mã định danh duy nhất (Silence ID).

Kiểm tra danh sách các Silence đang có hiệu lực trong hệ thống:

```bash
amtool silence query
```

Bạn cũng có thể mở trình duyệt truy cập:
* `http://localhost:9093/#/silences`: Xem giao diện quản trị các Silence, thời gian bắt đầu, kết thúc và người tạo trực quan.

---

### 4. Yêu Cầu Hoàn Thành Bước 3

1. Tệp `/root/alerting-lab/alertmanager.yml` chứa khối `inhibit_rules` hợp lệ.
2. Hệ thống Alertmanager có ít nhất **1 Silence đang ở trạng thái `active`** được tạo thành công qua `amtool`.

Sau khi hoàn tất, nhấn **Check** để hệ thống tự động kiểm tra Bước 3.
