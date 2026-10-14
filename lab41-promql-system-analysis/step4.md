# Bước 4: Điều Kiện Cảnh Báo Ngưỡng & Hàm Xếp Hạng Topk

Ở 3 bước trước, bạn đã học cách trích xuất và tính toán các chỉ số hạ tầng và ứng dụng. Trong bước cuối cùng này, bạn sẽ áp dụng **toán tử so sánh điều kiện cảnh báo (Alert Condition)** và **hàm xếp hạng `topk`** — hai công cụ tối quan trọng để tự động hóa giám sát và phát hiện nút thắt cổ chai.

---

### 1. Cơ Chế Lọc Theo Ngưỡng Cảnh Báo (Binary Comparisons as Filters)

Trong PromQL, các toán tử so sánh (`>`, `<`, `>=`, `<=`, `==`, `!=`) không chỉ trả về true/false mà hoạt động như một **bộ lọc động (Filter)**:
- Nếu biểu thức điều kiện không thỏa mãn: Prometheus trả về **tập rỗng (Empty result)**.
- Nếu biểu thức điều kiện thỏa mãn: Prometheus trả về **chuỗi thời gian kèm giá trị vi phạm**, sẵn sàng gửi sang Alertmanager để phát cảnh báo tới Slack/Telegram/PagerDuty.

Ví dụ: Thiết lập điều kiện cảnh báo khi tỷ lệ lỗi của dịch vụ vượt quá 3%:

```promql
(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100 > 3
```

Thử nghiệm chạy truy vấn kiểm tra xem hệ thống có đang rơi vào ngưỡng báo động hay không:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100 > 3' | \
  jq -r '.data.result[] | "ALERT TRIGGERED! Current Error Rate: \(.value[1]) %"'
```

---

### 2. Hàm Xếp Hạng Topk: Tìm "Kẻ Tội Đồ" Ngốn Lưu Lượng

Khi một cụm microservices có hàng trăm API, việc theo dõi từng endpoint là bất khả thi. Hàm **`topk(k, vector)`** cho phép bạn tự động chọn lọc ra **k đối tượng** có giá trị cao nhất.

Truy vấn tìm **Top 2 API Endpoint** có lưu lượng truy cập lớn nhất hệ thống:

```promql
topk(2, sum by (path) (rate(http_requests_total[2m])))
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=topk(2, sum by (path) (rate(http_requests_total[2m])))' | \
  jq -r '.data.result[] | "TOP ENDPOINT: \(.metric.path) -> \(.value[1]) req/s"'
```

---

### 3. Yêu Cầu Hoàn Thành Bước 4

Tổng hợp bộ 5 câu truy vấn PromQL chuẩn mực mà bất kỳ kỹ sư SRE nào cũng cần lưu vào tệp **/root/promql-lab/final-queries.txt**:

```bash
cat << 'EOF' > /root/promql-lab/final-queries.txt
CPU_USAGE=100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)
RAM_USAGE=100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
APP_RPS=sum(rate(http_requests_total[2m]))
APP_ERROR_RATE=(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100
APP_P95_LATENCY=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))
EOF
cat /root/promql-lab/final-queries.txt
```

Sau khi tạo tệp tổng kết, hãy nhấn **Check**. Hệ thống sẽ tự động thực thi cả 5 câu truy vấn của bạn qua Prometheus API để đánh giá độ chính xác toàn diện!
