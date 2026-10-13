# Bước 3: Khởi Chạy Loki & Định Tuyến Log Về Cụm Lưu Trữ

Sau khi quá trình trích xuất và chuẩn hóa log hoàn tất tại tầng xử lý, bước tiếp theo là khởi chạy kho lưu trữ tập trung **Grafana Loki** và thiết lập cơ chế **Định tuyến (Log Routing)** trong Fluent Bit để phân loại luồng dữ liệu theo nhãn dịch vụ.

---

### 1. Khởi chạy Grafana Loki Server

Khởi chạy container Loki chính thức trên cổng **3100** với chế độ mạng **--network host**:

```bash
docker rm -f loki 2>/dev/null || true
docker run -d --name loki --network host grafana/loki:2.9.2
```{{exec}}

Kiểm tra trạng thái sẵn sàng phục vụ của Loki qua endpoint **/ready**:

```bash
sleep 4
curl -s http://localhost:3100/ready
```{{exec}}

---

### 2. Khởi chạy Grafana Dashboard UI

Khởi chạy Grafana trên cổng **3000** với chế độ xác thực Anonymous Admin (không cần nhập tài khoản/mật khẩu) và tự động gắn kết Datasource Loki từ thư mục provisioning:

```bash
docker rm -f grafana 2>/dev/null || true
docker run -d --name grafana --network host \
  -e "GF_AUTH_ANONYMOUS_ENABLED=true" \
  -e "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin" \
  -v /root/centralized-logging-lab/datasources:/etc/grafana/provisioning/datasources \
  grafana/grafana:10.2.0
```{{exec}}

Kiểm tra sức khỏe dịch vụ Grafana qua HTTP API:

```bash
sleep 3
curl -s http://localhost:3000/api/health | jq .
```{{exec}}

---

### 3. Cấu hình cơ chế định tuyến (Routing) trong Fluent Bit

Khả năng định tuyến theo nhãn (Tag-based Routing) là một trong những thế mạnh lớn nhất của Fluent Bit. Thay vì đổ dồn mọi log vào một stream duy nhất, ta cấu hình hai khối **[OUTPUT]** riêng biệt sử dụng bộ lọc so khớp **Match**:
* Các bản ghi khớp nhãn **app.*** được gắn nhãn **service=order-api, type=application**.
* Các bản ghi khớp nhãn **web.*** được gắn nhãn **service=nginx-gateway, type=access**.

Cập nhật lại tệp **fluent-bit.conf**:

```bash
cd /root/centralized-logging-lab
cat << 'EOF' > fluent-bit.conf
[SERVICE]
    Flush         1
    Log_Level     info
    Parsers_File  parsers.conf

[INPUT]
    Name              tail
    Path              /var/log/apps/order-api.log
    Tag               app.orders
    Parser            json_parser
    Read_from_Head    On
    Refresh_Interval  1

[INPUT]
    Name              tail
    Path              /var/log/apps/nginx-access.log
    Tag               web.nginx
    Parser            nginx_parser
    Read_from_Head    On
    Refresh_Interval  1

[FILTER]
    Name          record_modifier
    Match         *
    Record        cluster apac-prod-01
    Record        environment production

[OUTPUT]
    Name                   loki
    Match                  app.*
    Host                   127.0.0.1
    Port                   3100
    Labels                 job=centralized-logging, service=order-api, type=application
    Auto_Kubernetes_Labels off

[OUTPUT]
    Name                   loki
    Match                  web.*
    Host                   127.0.0.1
    Port                   3100
    Labels                 job=centralized-logging, service=nginx-gateway, type=access
    Auto_Kubernetes_Labels off
EOF
cat fluent-bit.conf
```{{exec}}

---

### 4. Khởi chạy Fluent Bit Daemon

Khởi chạy container Fluent Bit dài hạn kết nối trực tiếp với Loki:

```bash
docker rm -f fluent-bit 2>/dev/null || true
docker run -d --name fluent-bit --network host \
  -v /root/centralized-logging-lab/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf \
  -v /root/centralized-logging-lab/parsers.conf:/fluent-bit/etc/parsers.conf \
  -v /var/log/apps:/var/log/apps \
  fluent/fluent-bit:2.2 /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf
```{{exec}}

Kiểm tra trạng thái cả ba container đang vận hành:

```bash
docker ps --filter "name=loki" --filter "name=fluent-bit" --filter "name=grafana" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```{{exec}}

---

### 5. Kiểm tra việc phân vùng luồng nhật ký trong Loki

Chờ 5 giây để Fluent Bit đẩy các bản ghi log ban đầu vào Loki, sau đó kiểm tra danh sách nhãn đã được phân vùng:

```bash
sleep 5
curl -s http://localhost:3100/loki/api/v1/labels | jq .
```{{exec}}

Kiểm tra các giá trị của nhãn **service**:

```bash
curl -s http://localhost:3100/loki/api/v1/label/service/values | jq .
```{{exec}}

Xuất kết quả danh sách nhãn ra tệp kiểm tra **loki-routing-labels.json**:

```bash
curl -s http://localhost:3100/loki/api/v1/labels > /root/centralized-logging-lab/loki-routing-labels.json
cat /root/centralized-logging-lab/loki-routing-labels.json | jq .
```{{exec}}

Nhấn **Check** để hoàn thành bước 3.
