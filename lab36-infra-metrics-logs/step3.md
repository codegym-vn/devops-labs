# Bước 3: Triển Khai Grafana Loki & Promtail Shipper Thu Thập Logs

Song song với việc đo lường chỉ số định lượng (Metrics), việc thu thập có tổ chức các bản ghi sự kiện (Logs) từ hạ tầng máy chủ là yêu cầu sống còn trong kỹ thuật SRE.

Trong hệ sinh thái quan sát hiện đại, **Grafana Loki** là giải pháp lưu trữ nhật ký tập trung được ưa chuộng nhờ chi phí vận hành thấp và tốc độ xử lý vượt trội. Thay vì lập chỉ mục (index) toàn bộ nội dung văn bản gây ngốn dung lượng RAM và đĩa như các hệ thống truyền thống, Loki chỉ đánh chỉ mục cho các trường nhãn định danh (Metadata Labels) tương tự như Prometheus. **Promtail** là tác tử (Agent/Shipper) chịu trách nhiệm đọc các tệp log từ máy chủ, gắn nhãn định danh và chuyển tiếp (Push) trực tiếp về Loki.

---

### 1. Khởi chạy Grafana Loki Server

Khởi chạy container Loki chính thức trên cổng **3100** với chế độ mạng **--network host**:

```bash
cd /root/infra-monitoring-lab
docker rm -f loki 2>/dev/null || true
docker run -d --name loki --network host grafana/loki:2.9.2
```{{exec}}

Kiểm tra trạng thái sẵn sàng phục vụ của Loki qua endpoint **/ready**:

```bash
sleep 4
curl -s http://localhost:3100/ready
```{{exec}}

Khi hệ thống trả về thông báo **ready**, dịch vụ Loki đã sẵn sàng tiếp nhận luồng dữ liệu log.

---

### 2. Thiết kế cấu hình Promtail Shipper

Tạo tệp cấu hình **promtail-config.yml** để hướng dẫn Promtail đọc tất cả các tệp nhật ký trong thư mục **/var/log/infrastructure/*.log**, lưu trạng thái con trỏ đọc (Positions) tại **/tmp/positions.yaml** và đẩy dữ liệu về Loki:

```bash
cd /root/infra-monitoring-lab
cat << 'EOF' > promtail-config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: 'infrastructure-logs'
    static_configs:
      - targets:
          - localhost
        labels:
          job: 'infrastructure'
          host: 'srv-prod-01'
          env: 'production'
          __path__: /var/log/infrastructure/*.log
EOF
cat promtail-config.yml
```{{exec}}

---

### 3. Khởi chạy Promtail Container

Chạy Promtail với các phân vùng ánh xạ tệp cấu hình và thư mục log hệ thống:

```bash
docker rm -f promtail 2>/dev/null || true
docker run -d --name promtail --network host \
  -v /root/infra-monitoring-lab/promtail-config.yml:/etc/promtail/config.yml \
  -v /var/log/infrastructure:/var/log/infrastructure \
  -v /tmp:/tmp \
  grafana/promtail:2.9.2 -config.file=/etc/promtail/config.yml
```{{exec}}

Kiểm tra trạng thái container Promtail:

```bash
docker ps --filter "name=promtail" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```{{exec}}

---

### 4. Kiểm tra việc lập chỉ mục nhãn (Labels) trong Loki

Chờ 5 giây để Promtail đồng bộ các dòng log ban đầu từ **/var/log/infrastructure/system.log** sang Loki. Sau đó truy vấn danh sách nhãn đã được Loki ghi nhận:

```bash
sleep 5
curl -s http://localhost:3100/loki/api/v1/labels | jq .
```{{exec}}

Kiểm tra giá trị của nhãn **job**:

```bash
curl -s http://localhost:3100/loki/api/v1/label/job/values | jq .
```{{exec}}

Xuất danh sách nhãn ra tệp **loki-labels.json**:

```bash
curl -s http://localhost:3100/loki/api/v1/labels > /root/infra-monitoring-lab/loki-labels.json
cat /root/infra-monitoring-lab/loki-labels.json | jq .
```{{exec}}

Nhấn **Check** để hoàn thành bước 3.
