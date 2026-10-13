# Bước 2: Thiết Kế Pipeline Xử Lý Log Với Fluent Bit

**Fluent Bit** là dự án mã nguồn mở trực thuộc CNCF, được thiết kế chuyên biệt để đóng vai trò là một Log Processor & Forwarder siêu nhẹ với kiến trúc Pipeline chuẩn mực gồm 5 giai đoạn:

```text
 [INPUT] ──► [PARSER] ──► [FILTER] ──► [BUFFER] ──► [ROUTING / OUTPUT]
```

Trong bước này, bạn sẽ thiết lập bộ giải mã **Parser** để cấu trúc hóa log chuỗi văn bản của Nginx và log JSON của Order API, đồng thời áp dụng **Filter** để làm giàu metadata quản trị trước khi xuất bản.

---

### 1. Tạo tệp cấu hình Parser (parsers.conf)

Tạo tệp **parsers.conf** khai báo hai bộ giải mã chuyên dụng:
1. **json_parser**: Tự động bóc tách các cặp key-value trong chuỗi JSON thành các trường độc lập.
2. **nginx_parser**: Sử dụng biểu thức chính quy (Regex) để phân rã chuỗi Nginx Combined Log thành các trường: **client_ip**, **method**, **path**, **status_code**, **response_size**:

```bash
cd /root/centralized-logging-lab
cat << 'EOF' > parsers.conf
[PARSER]
    Name        json_parser
    Format      json
    Time_Key    timestamp
    Time_Format %Y-%m-%dT%H:%M:%SZ

[PARSER]
    Name        nginx_parser
    Format      regex
    Regex       ^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +(?<protocol>\S+))?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)")?$
    Time_Key    time
    Time_Format %d/%b/%Y:%H:%M:%S %z
EOF
cat parsers.conf
```{{exec}}

---

### 2. Thiết kế tệp cấu hình chính (fluent-bit.conf)

Tạo tệp **fluent-bit.conf** tích hợp đầy đủ các khối Input, Filter và Output:
* **[SERVICE]**: Chỉ định chu kỳ xả dữ liệu (Flush 1 giây) và nạp tệp **parsers.conf**.
* **[INPUT]**:
  * Đọc **/var/log/apps/order-api.log** gắn nhãn Tag **app.orders** và áp dụng **json_parser**.
  * Đọc **/var/log/apps/nginx-access.log** gắn nhãn Tag **web.nginx** và áp dụng **nginx_parser**.
  * Đọc từ đầu tệp (**Read_from_Head On**) để thu nạp toàn bộ lịch sử log hiện có.
* **[FILTER]**: Sử dụng plugin **record_modifier** để tự động bổ sung hai trường metadata quản trị hạ tầng: **cluster=apac-prod-01** và **environment=production**.
* **[OUTPUT]**: Tạm thời xuất ra màn hình điều khiển (**stdout**) để kiểm tra độ chính xác của quá trình bóc tách.

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
    Name          stdout
    Match         *
EOF
cat fluent-bit.conf
```{{exec}}

---

### 3. Kiểm tra tính toàn vẹn của Pipeline xử lý

Chạy thử nghiệm container Fluent Bit ở chế độ foreground trong 4 giây để thẩm tra việc xử lý dữ liệu và lưu kết quả:

```bash
docker run --rm --name fb-test-run \
  -v /root/centralized-logging-lab/fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf \
  -v /root/centralized-logging-lab/parsers.conf:/fluent-bit/etc/parsers.conf \
  -v /var/log/apps:/var/log/apps \
  fluent/fluent-bit:2.2 /fluent-bit/bin/fluent-bit -c /fluent-bit/etc/fluent-bit.conf > fluent-bit-test.log 2>&1 &
FB_PID=$!

sleep 4
docker stop fb-test-run 2>/dev/null || true
kill $FB_PID 2>/dev/null || true
```{{exec}}

Kiểm tra kết quả trích xuất trong tệp **fluent-bit-test.log**:

```bash
cat fluent-bit-test.log | grep -E "app.orders|web.nginx" -A 4 | head -n 25
```{{exec}}

Quan sát rằng cả hai nguồn log:
1. Chuỗi ký tự thô của Nginx đã được bóc tách thành các trường rõ ràng: **remote**, **method**, **path**, **code**.
2. Toàn bộ bản ghi đều đã được tự động làm giàu thêm hai nhãn **cluster: "apac-prod-01"** và **environment: "production"**.

Nhấn **Check** để hoàn thành bước 2.
