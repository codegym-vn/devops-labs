# Bước 4: Kỹ Thuật Hot-Reload Cấu Hình Zero-Downtime

Trong môi trường doanh nghiệp quy mô lớn, máy chủ và container liên tục được tạo mới hoặc thay đổi địa chỉ mạng. Nếu mỗi lần thêm bớt Target ta lại phải khởi động lại Prometheus (`docker restart prometheus`), toàn bộ chuỗi thu thập số liệu sẽ bị đứt gãy (Data Gaps) và các quy tắc cảnh báo có thể bị đánh giá sai lệch.

Để đạt chuẩn vận hành Zero-downtime, Prometheus cung cấp cơ chế **Hot-reload (Nạp lại cấu hình động trong khi tiến trình vẫn đang chạy)**.

---

### 1. Thử Thách Cập Nhật Nhãn Metadata

Bổ sung thêm một nhãn định danh quản trị mới `tier: 'backend'` vào tác vụ thu thập của `node`:

```bash
sed -i "/datacenter: 'hanoi-dc1'/a \          tier: 'backend'" /root/prometheus-lab/prometheus.yml
git diff /root/prometheus-lab/prometheus.yml 2>/dev/null || cat /root/prometheus-lab/prometheus.yml
```

Lúc này, tệp cấu hình trên đĩa đã thay đổi, nhưng trong bộ nhớ của Prometheus vẫn đang chạy cấu hình cũ.

---

### 2. Kích Hoạt Hot-Reload Bằng HTTP POST

Gửi HTTP POST request vào endpoint vòng đời `/-/reload`:

```bash
curl -i -X POST http://localhost:9090/-/reload
```

Nếu thành công, máy chủ sẽ trả về mã **HTTP 200 OK**.

Kiểm tra nhật ký hoạt động (Logs) của Prometheus để thấy quá trình nạp lại cấu hình diễn ra trong tích tắc:

```bash
docker logs --tail 10 prometheus
```
Bạn sẽ thấy thông báo:
```text
ts=... msg="Loading configuration file" filename=/etc/prometheus/prometheus.yml
ts=... msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml
```

---

### 3. Nghiệm Thu Nhãn Mới Trên Target

Truy vấn lại danh sách active targets để kiểm tra xem nhãn `tier="backend"` đã được áp dụng hay chưa:

```bash
curl -s http://localhost:9090/api/v1/targets | \
  jq -r '.data.activeTargets[] | select(.labels.job == "node") | .labels'
```

Kết quả trả về phải chứa đầy đủ:
```json
{
  "datacenter": "hanoi-dc1",
  "environment": "production",
  "instance": "localhost:9100",
  "job": "node",
  "tier": "backend"
}
```

Kiểm tra thời gian chạy (Uptime) của container để chứng minh tiến trình không hề bị restart:

```bash
docker ps --filter "name=prometheus" --format "Container: {{.Names}} | Uptime: {{.Status}}"
```

---

### 4. Yêu Cầu Hoàn Thành Bước 4

Nhấn **Check** để hoàn thành bài thực hành. Hệ thống sẽ kiểm tra xem nhãn mới đã có hiệu lực trên Prometheus API mà container không bị gián đoạn hay không.
