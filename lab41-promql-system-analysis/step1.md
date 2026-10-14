# Bước 1: Làm Chủ Bộ Lọc Nhãn & Phân Biệt Các Loại Vector

Trong PromQL, toàn bộ dữ liệu được tổ chức dưới dạng các chuỗi thời gian được gắn nhãn (Labeled Time-Series). Trước khi tính toán số liệu phức tạp, bạn cần làm chủ cách **chọn lọc dữ liệu chuẩn xác**.

---

### 1. Phân Biệt Instant Vector Và Range Vector

PromQL có 2 kiểu vector dữ liệu nền tảng:
- **Instant Vector (Vector tức thời):** Trả về **đúng 1 giá trị duy nhất** tại thời điểm hiện tại cho mỗi chuỗi thời gian (Ví dụ: `http_requests_total`). Instant Vector là kiểu dữ liệu duy nhất có thể vẽ đồ thị (Graph) trên giao diện.
- **Range Vector (Vector phạm vi):** Trả về **một mảng các mẫu giá trị** biến thiên trong một khoảng thời gian trong quá khứ, được biểu thị bằng dấu ngoặc vuông `[...]` (Ví dụ: `http_requests_total[2m]`). Range Vector không thể vẽ đồ thị trực tiếp mà luôn đóng vai trò là tham số đầu vào cho các hàm tính toán tỷ lệ như `rate()`, `increase()`.

---

### 2. Bốn Bộ Lọc Nhãn (Label Matchers) Trong PromQL

Khi truy vấn một metric, ta dùng dấu ngoặc nhọn `{...}` để lọc nhãn theo 4 toán tử:

| Toán tử | Ý nghĩa | Ví dụ |
| :--- | :--- | :--- |
| **`=`** | Bằng chính xác chuỗi | `http_requests_total{method="POST"}` |
| **`!=`** | Khác chuỗi | `http_requests_total{method!="GET"}` |
| **`=~`** | Khớp biểu thức chính quy (Regex) | `http_requests_total{path=~"/api/.*"}` |
| **`!~`** | Không khớp biểu thức chính quy | `http_requests_total{status!~"2.."}` |

---

### 3. Thực Hành Truy Vấn Qua Dòng Lệnh & Web UI

Bạn có thể mở giao diện Web tại `http://localhost:9090/graph` để nhập câu lệnh, hoặc dùng lệnh `curl` gửi trực tiếp tới Prometheus HTTP Query API:

```bash
# 1. Truy vấn tất cả request POST
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=http_requests_total{method="POST"}' | \
  jq -r '.data.result[] | {path: .metric.path, status: .metric.status, count: .value[1]}'
```

```bash
# 2. Truy vấn tất cả các request gặp lỗi (mã trạng thái không phải 2xx)
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=http_requests_total{status!~"2.."}' | \
  jq -r '.data.result[] | {method: .metric.method, path: .metric.path, status: .metric.status, total: .value[1]}'
```

---

### 4. Yêu Cầu Hoàn Thành Bước 1

Hãy viết câu truy vấn PromQL để lọc **tất cả các request gặp lỗi (mã `status` không phải 2xx) của riêng đường dẫn `path="/api/orders"`**, sau đó lưu câu lệnh này vào tệp **/root/promql-lab/step1-query.txt**:

```bash
echo 'http_requests_total{path="/api/orders",status!~"2.."}' > /root/promql-lab/step1-query.txt
cat /root/promql-lab/step1-query.txt
```

Sau khi lưu tệp, nhấn **Check** để hệ thống tự động thực thi câu truy vấn của bạn lên Prometheus và kiểm tra kết quả trả về.
