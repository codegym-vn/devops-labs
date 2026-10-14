# Bước 3: Bóc Tách Nguyên Nhân Gốc Với Centralized Logging

Ở Bước 2, Distributed Tracing đã chỉ điểm chính xác **nghi phạm**:
- Dịch vụ: **`payment-service`**
- Span nghẽn: **`db_acquire_connection`**

Tuy nhiên, Tracing chỉ cho bạn biết **NƠI NÀO** bị nghẽn (`db_acquire_connection` mất 2000ms rồi fail). Tracing không thể giải thích **TẠI SAO**:
- Có phải do CSDL PostgreSQL/MySQL bị rớt mạng?
- Do sai mật khẩu kết nối Database?
- Hay do một tham số cấu hình tài nguyên bị giới hạn bất hợp lý?

Để tìm ra **Nguyên nhân gốc rễ (Root Cause)**, bạn cần liên kết mã `trace_id` với kho nhật ký tập trung **Centralized Logging (Grafana Loki)**.

---

### 1. Kỹ Thuật Log Correlation (Liên Kết Trace Với Log)

Toàn bộ ứng dụng trong hệ thống đã được cấu hình ghi log có cấu trúc dạng JSON và đẩy về Grafana Loki qua Fluent Bit với nhãn `service="payment-service"`.

Mỗi dòng log nghiệp vụ đều được gắn kèm mã `trace_id` tương ứng với request đang xử lý.

#### Cách 1: Truy vấn Loki bằng LogQL qua HTTP API
Dùng mã `SAMPLE_TRACE_ID` bạn tìm được ở Bước 2 để lọc chính xác các bản ghi log liên quan:

```bash
# Thay the <TRACE_ID> bang ma trace cua ban
TRACE_ID=$(grep "SAMPLE_TRACE_ID=" /root/incident-report/step2-trace.txt | cut -d'=' -f2)

curl -s -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode "query={service=\"payment-service\"} |= \"$TRACE_ID\"" | jq .
```

Hoặc truy vấn nhanh tất cả các dòng log có mức độ `error` trong dịch vụ `payment-service`:

```bash
curl -s -G "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="payment-service"} |= "error"' | \
  jq -r '.data.result[].values[][1]' | jq .
```

#### Cách 2: Kiểm tra trực tiếp tệp log cục bộ
Bạn cũng có thể đối chiếu tệp log nguyên bản tại **/var/log/apps/payment-service.log**:

```bash
grep -i "error" /var/log/apps/payment-service.log | tail -n 1 | jq .
```

---

### 2. Bóc Tách Nguyên Nhân Gốc Rễ (Root Cause Discovery)

Khi phân tích log lỗi, bạn sẽ nhìn thấy thông điệp cốt lõi:

```json
{
  "level": "error",
  "service": "payment-service",
  "error_name": "ConnectionPoolExhaustedError",
  "message": "Timeout (2000ms) waiting for database connection. Pool capacity reached: active=2, max=2, waiting=12"
}
```

Bây giờ, hãy kiểm tra tệp cấu hình của Payment Service tại **/root/incident-lab/payment-service.env**:

```bash
cat /root/incident-lab/payment-service.env
```

Bạn phát hiện ra điều gì bất thường?
- Biến **`DB_POOL_MAX=2`**!
- Hồ chứa kết nối cơ sở dữ liệu (Connection Pool) chỉ cho phép tối đa **2 kết nối đồng thời**.
- Trong khi đó, lưu lượng truy cập thực tế liên tục gửi 3-4 giao dịch cùng lúc. Khi 2 kết nối đầu tiên đang bận xử lý, tất cả các request đến sau bị dồn vào hàng đợi (`waiting queue`). Khi thời gian chờ vượt quá `DB_TIMEOUT_MS=2000ms`, ứng dụng buộc phải hủy request và trả về lỗi 503, khiến Nginx ném ra mã 504 Gateway Timeout!

---

### 3. Yêu Cầu Hoàn Thành Bước 3

Ghi lại kết luận phân tích nguyên nhân gốc rễ vào tệp **/root/incident-report/step3-rootcause.txt**:

```bash
cat << 'EOF' > /root/incident-report/step3-rootcause.txt
ROOT_CAUSE=CONNECTION_POOL_EXHAUSTED
ERROR_CLASS=ConnectionPoolExhaustedError
FAULTY_CONFIG_FILE=/root/incident-lab/payment-service.env
FAULTY_VARIABLE=DB_POOL_MAX
CURRENT_VALUE=2
EOF
```

Nhấn **Check** để xác thực kết luận Root Cause của bạn trước khi bước vào giai đoạn Hotfix cứu hệ thống.
