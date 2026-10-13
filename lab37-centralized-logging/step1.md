# Bước 1: Khởi Tạo Môi Trường Đa Nguồn & Khảo Sát Log Phân Tán

Trong môi trường doanh nghiệp thực tế, các ứng dụng không phát sinh nhật ký theo một định dạng đồng nhất. Hệ thống phân tán thường tồn tại song song nhiều định dạng khác nhau: log phi cấu trúc dạng văn bản truyền thống từ Web Server (Nginx, Apache) và log có cấu trúc chuẩn JSON từ các vi dịch vụ (Microservices).

Trong bước này, bạn sẽ thiết lập môi trường giả lập đa nguồn nhật ký và trải nghiệm trực tiếp bài toán phân mảnh dữ liệu trước khi triển khai hệ thống tập trung.

---

### 1. Khảo sát cấu trúc tệp nhật ký đa nguồn

Hệ thống đã chuẩn bị sẵn thư mục lưu trữ nhật ký tại **/var/log/apps**:

```bash
ls -lh /var/log/apps/
```

Kiểm tra nội dung định dạng nhật ký của **Order API** (Định dạng JSON có cấu trúc):

```bash
cat /var/log/apps/order-api.log | jq .
```

Kiểm tra nội dung định dạng nhật ký của **Nginx Gateway** (Định dạng Combined Log Format dạng chuỗi phân cách khoảng trắng):

```bash
cat /var/log/apps/nginx-access.log
```

---

### 2. Tạo kịch bản sinh nhật ký tự động

Để mô phỏng lưu lượng truy cập thực tế, hãy tạo kịch bản **generate-sample-logs.sh** để ghi đồng thời các sự kiện truy cập vào cả hai dịch vụ:

```bash
cd /root/centralized-logging-lab
cat << 'EOF' > generate-sample-logs.sh
#!/bin/bash
ORDER_LOG="/var/log/apps/order-api.log"
NGINX_LOG="/var/log/apps/nginx-access.log"

echo "Dang sinh luong nhat ky mau vao cac nguon..."

# Giao dich 1: Don hang thanh cong
REQ_ID="req_$(date +%s)_01"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NGINX_TIME=$(date -u +"%d/%b/%Y:%H:%M:%S +0000")

echo "10.0.1.20 - - [$NGINX_TIME] \"POST /api/checkout HTTP/1.1\" 200 412 \"https://shop.example.com\" \"Mozilla/5.0\"" >> "$NGINX_LOG"
echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"info\",\"service\":\"order-api\",\"req_id\":\"$REQ_ID\",\"message\":\"Checkout completed successfully\",\"user_id\":\"usr_912\",\"amount\":2400}" >> "$ORDER_LOG"

# Giao dich 2: Loi het hang trong kho (Business Logic Error)
REQ_ID="req_$(date +%s)_02"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NGINX_TIME=$(date -u +"%d/%b/%Y:%H:%M:%S +0000")

echo "10.0.1.21 - - [$NGINX_TIME] \"POST /api/checkout HTTP/1.1\" 400 185 \"https://shop.example.com\" \"Mozilla/5.0\"" >> "$NGINX_LOG"
echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"warn\",\"service\":\"order-api\",\"req_id\":\"$REQ_ID\",\"message\":\"Insufficient stock for item laptop-pro\",\"user_id\":\"usr_304\",\"amount\":1200}" >> "$ORDER_LOG"

# Giao dich 3: Su co cong thanh toan timeout (Server Error 500)
REQ_ID="req_$(date +%s)_03"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NGINX_TIME=$(date -u +"%d/%b/%Y:%H:%M:%S +0000")

echo "10.0.1.22 - - [$NGINX_TIME] \"POST /api/checkout HTTP/1.1\" 500 520 \"https://shop.example.com\" \"Mozilla/5.0\"" >> "$NGINX_LOG"
echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"error\",\"service\":\"order-api\",\"req_id\":\"$REQ_ID\",\"message\":\"Payment gateway timeout after 5000ms\",\"user_id\":\"usr_551\",\"amount\":3500}" >> "$ORDER_LOG"

echo "Da sinh thanh cong cac giao dich mau vao 2 nguon log."
EOF
chmod +x generate-sample-logs.sh
./generate-sample-logs.sh
```{{exec}}

---

### 3. Trải nghiệm nỗi đau phân mảnh dữ liệu (Log Fragmentation Pain)

Hãy thử hình dung khi một khách hàng báo cáo giao dịch thất bại:
* Để biết mã lỗi HTTP mà khách hàng nhận được, bạn phải dùng lệnh lọc chuỗi trên tệp Nginx:
  ```bash
  grep " 500 " /var/log/apps/nginx-access.log
  ```{{exec}}
* Để biết nguyên nhân chi tiết tại sao giao dịch lỗi (do hết hàng, timeout hay lỗi code), bạn lại phải mở tệp thứ hai và dùng tiện ích jq:
  ```bash
  cat /var/log/apps/order-api.log | jq 'select(.level=="error")'
  ```{{exec}}

Khi hệ thống có hàng chục máy chủ và hàng trăm container vi dịch vụ, việc SSH thủ công vào từng máy và chắp vá log là điều bất khả thi. Đó chính là lý do chúng ta cần **Centralized Logging**.

---

### 4. Lưu trạng thái kiểm tra bước 1

Ghi nhận tổng số dòng log của các dịch vụ ra tệp kiểm tra:

```bash
wc -l /var/log/apps/*.log > /root/centralized-logging-lab/initial-logs-status.txt
cat /root/centralized-logging-lab/initial-logs-status.txt
```{{exec}}

Nhấn **Check** để hoàn thành bước 1.
