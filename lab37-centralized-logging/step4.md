# Bước 4: Truy Vết Sự Cố Đa Nguồn & Phân Tích Bằng LogQL

Sau khi hệ thống Centralized Logging đã hoàn tất thiết lập, lợi ích lớn nhất mà nó mang lại là khả năng **Truy vết sự cố xuyên suốt đa tầng dịch vụ (Cross-Service Incident Correlation)**: chỉ với một câu truy vấn duy nhất tại kho lưu trữ tập trung, bạn có thể tái hiện toàn bộ đường đi của một giao dịch từ Gateway cho tới tận Backend Service.

---

### 1. Kịch bản mô phỏng sự cố thanh toán phân tán

Tạo và chạy script **simulate-incident.sh** để ghi nhận một chuỗi sự cố giao dịch có mã định danh **req_critical_8899** xuất hiện đồng thời trên cả Nginx Gateway và Order Service:

```bash
cd /root/centralized-logging-lab
cat << 'EOF' > simulate-incident.sh
#!/bin/bash
ORDER_LOG="/var/log/apps/order-api.log"
NGINX_LOG="/var/log/apps/nginx-access.log"

REQ_ID="req_critical_8899"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NGINX_TIME=$(date -u +"%d/%b/%Y:%H:%M:%S +0000")

echo "Dang ghi nhan su co giao dich xuyen tang voi ma $REQ_ID..."

# 1. Nginx Gateway ghi nhan phan hoi loi HTTP 500 toi client
echo "10.0.2.88 - - [$NGINX_TIME] \"POST /api/checkout HTTP/1.1\" 500 520 \"https://shop.example.com\" \"MobileApp/2.4\"" >> "$NGINX_LOG"

# 2. Order Service ghi nhan exception can nguyen loi Deadlock
echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"error\",\"service\":\"order-api\",\"req_id\":\"$REQ_ID\",\"message\":\"Database deadlock detected during payment commit for order ord_8899\",\"user_id\":\"usr_771\",\"amount\":4200}" >> "$ORDER_LOG"

# 3. Order Service ghi nhan rollback giao dich
echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"error\",\"service\":\"order-api\",\"req_id\":\"$REQ_ID\",\"message\":\"Transaction rolled back with fatal exception: Connection pool exhausted\",\"user_id\":\"usr_771\",\"amount\":4200}" >> "$ORDER_LOG"

echo "Da tao xong su co phan tan."
EOF
chmod +x simulate-incident.sh
./simulate-incident.sh
```{{exec}}

Chờ 4 giây để Fluent Bit đọc và xả log mới sang Loki:

```bash
sleep 4
```{{exec}}

---

### 2. Thực thi các truy vấn LogQL điều tra tập trung

Sử dụng động cơ truy vấn **LogQL** của Loki để điều tra sự cố:

#### A. Truy vấn toàn bộ log của cổng vào Nginx Gateway
Lọc các yêu cầu kết thúc bằng mã lỗi máy chủ HTTP 500:

```bash
curl -s -G --data-urlencode 'query={service="nginx-gateway"} |= " 500 "' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

#### B. Truy vấn toàn bộ log lỗi của Order API
Tìm kiếm các bản ghi có chứa chuỗi **error** trong dịch vụ Order Service:

```bash
curl -s -G --data-urlencode 'query={service="order-api"} |= "error"' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

#### C. Truy vết liên kết xuyên tầng theo mã giao dịch (Correlated Incident Tracing)
Đây là sức mạnh thực sự của Centralized Logging: không cần biết log nằm ở tệp nào hay máy chủ nào, chỉ cần lọc theo mã định danh sự cố trên toàn bộ kho lưu trữ **job="centralized-logging"**:

```bash
curl -s -G --data-urlencode 'query={job="centralized-logging"} |= "req_critical_8899"' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

Toàn bộ các dòng log liên quan đến mã lỗi từ cả Gateway lẫn Backend đều hiển thị liền mạch trên cùng một dòng thời gian.

#### D. Thống kê tổng số lượng log lỗi phát sinh (Log-to-Metrics)
Sử dụng hàm **count_over_time** để đếm tổng số lượng lỗi trong vòng 1 giờ qua trên toàn bộ hệ thống:

```bash
curl -s -G --data-urlencode 'query=count_over_time({job="centralized-logging"} |= "error" [1h])' http://localhost:3100/loki/api/v1/query | jq '.data.result[] | {metric: .metric, error_total: .value[1]}'
```{{exec}}

---

### 3. Trực quan hóa nhật ký trên giao diện Grafana Dashboard UI

Sau khi truy vấn bằng dòng lệnh, bạn có thể mở giao diện đồ họa Grafana để phân tích đồ thị và theo dõi luồng log trực quan:

* **Cách 1 (Nhanh nhất trên Killercoda):** Bấm trực tiếp vào liên kết sau để mở giao diện Grafana trong tab mới: [Mở Grafana Dashboard (Cổng 3000)]({{TRAFFIC_HOST1_3000}})
* **Cách 2:** Trên thanh điều hướng phía trên của Killercoda (ngay cạnh **Tab 1**, **Tab 2**), bấm vào dấu cộng **+** -> Chọn **Select Port to View on Host 1** -> Nhập số cổng **3000** và nhấn Enter.
* **Cách 3 (Nếu thực hành trên máy tính cá nhân):** Mở trình duyệt web và truy cập địa chỉ **http://localhost:3000**.

Sau khi mở giao diện:
1. Giao diện Grafana đã được cấu hình tự động đăng nhập quyền Quản trị (Admin) và gắn sẵn nguồn dữ liệu **Loki**.
2. Tại menu bên trái, nhấn vào biểu tượng la bàn **Explore** (khám phá dữ liệu).
4. Tại thanh nhập câu lệnh truy vấn (Query builder), nhập:
   **{job="centralized-logging"}**
   Sau đó nhấn nút xanh **Run query** (hoặc tổ hợp phím Shift + Enter).
5. Quan sát các thành phần trực quan:
   * **Biểu đồ cột (Log Volume Bar Chart):** Hiển thị trực quan mật độ log theo từng giây, giúp phát hiện đột biến lưu lượng (Spike).
   * **Danh sách log chi tiết:** Nhấn vào một dòng log bất kỳ để mở rộng xem các trường đã được Fluent Bit bóc tách tự động: **service**, **cluster**, **req_id**, **amount**, **environment**.
6. Thử nghiệm lọc riêng các lỗi hệ thống:
   **{service="order-api"} |= "error"**
   Nhấn **Live** ở góc trên bên phải để theo dõi luồng log đổ về trực tiếp theo thời gian thực.

---

### 4. Xuất báo cáo tổng kết hệ thống Centralized Logging

Lưu kết quả điều tra sự cố liên kết ra tệp báo cáo **centralized-logging-report.json**:

```bash
curl -s -G --data-urlencode 'query={job="centralized-logging"} |= "req_critical_8899"' http://localhost:3100/loki/api/v1/query_range > /root/centralized-logging-lab/centralized-logging-report.json
cat /root/centralized-logging-lab/centralized-logging-report.json | jq .
```{{exec}}

Nhấn **Check** để hoàn thành bài lab.
