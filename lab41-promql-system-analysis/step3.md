# Bước 3: Phân Tích SLA/SLO Ứng Dụng Theo Phương Pháp RED

Trong kiến trúc Microservices và Web API, hạ tầng CPU/RAM thấp không đồng nghĩa với việc ứng dụng hoạt động tốt. Để giám sát trải nghiệm người dùng thực tế và cam kết chất lượng dịch vụ (SLA/SLO), các kỹ sư SRE áp dụng phương pháp **RED**:
- **R (Rate):** Lưu lượng truy cập (Yêu cầu mỗi giây - RPS).
- **E (Errors):** Tỷ lệ lỗi phát sinh (Phần trăm request 5xx).
- **D (Duration):** Thời gian phản hồi của dịch vụ (Độ trễ p95 / p99 Percentile).

---

### 1. Rate: Tính Tốc Độ Yêu Cầu Mỗi Giây (Throughput RPS)

Metric `http_requests_total` là dạng Counter đếm tổng request. Sử dụng hàm `rate()` để tính tốc độ thay đổi mỗi giây và hàm tổng hợp `sum()` để gộp tất cả các nhãn:

```promql
sum(rate(http_requests_total[2m]))
```

Nếu muốn bóc tách xem mỗi API Endpoint (`path`) đang gánh bao nhiêu RPS:

```promql
sum by (path) (rate(http_requests_total[2m]))
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=sum by (path) (rate(http_requests_total[2m]))' | \
  jq -r '.data.result[] | "\(.metric.path) -> \(.value[1]) req/s"'
```

---

### 2. Errors: Tính Tỷ Lệ Phần Trăm (%) Lỗi Máy Chủ 5xx

Tỷ lệ lỗi là căn cứ trực tiếp để thiết lập cảnh báo và đánh giá Error Budget:
$$\text{Error Rate (\%)} = \frac{\text{Số request 5xx mỗi giây}}{\text{Tổng số request mỗi giây}} \times 100$$

Công thức PromQL:

```promql
(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=(sum(rate(http_requests_total{status=~"5.."}[2m])) / sum(rate(http_requests_total[2m]))) * 100' | \
  jq -r '.data.result[] | "ERROR RATE: \(.value[1]) %"'
```

---

### 3. Duration: Tính Độ Trễ 95th Percentile Bằng Histogram Quantile

Tại sao **không bao giờ** dùng độ trễ trung bình (Average Latency) để đo SLA?
- Độ trễ trung bình sẽ làm lu mờ hoàn toàn các request bị treo chậm (Outliers).
- **p95 Latency = 0.25s** nghĩa là: *95% người dùng nhận kết quả dưới 250ms, và chỉ có 5% người dùng bị chậm hơn mức này*.

Ứng dụng mẫu đã ghi nhận thời gian thực thi vào metric dạng Histogram `http_request_duration_seconds_bucket` kèm nhãn ngưỡng `le` (less than or equal).

Hàm **`histogram_quantile(φ, vector)`** sẽ tính toán giá trị bách phân vị dựa trên phân phối bucket:

```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))
```

Thử nghiệm truy vấn:

```bash
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))' | \
  jq -r '.data.result[] | "P95 LATENCY: \(.value[1]) seconds"'
```

---

### 4. Yêu Cầu Hoàn Thành Bước 3

Lưu câu truy vấn tính **độ trễ bách phân vị p95 của toàn bộ hệ thống** vào tệp **/root/promql-lab/step3-p95-query.txt**:

```bash
echo 'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))' > /root/promql-lab/step3-p95-query.txt
cat /root/promql-lab/step3-p95-query.txt
```

Sau khi lưu tệp, nhấn **Check** để hệ thống đánh giá câu truy vấn Histogram của bạn.
