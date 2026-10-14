# Bước 2: Thực Thi Kiểm Thử Baseline & Đo Lường Throughput, Latency

Sau khi kịch bản đã vượt qua Smoke Test, trong bước này bạn sẽ thực thi toàn bộ kịch bản Baseline trong 15 giây với 10 Virtual Users (VUs) liên tục, học cách đọc báo cáo số liệu chuẩn của k6 và xuất tệp tóm tắt hiệu năng.

---

### 1. Ý Nghĩa Của Các Chỉ Số Hiệu Năng Cốt Lõi

Khi k6 kết thúc quá trình chạy tải, nó sẽ in ra một bảng tổng hợp. Là kỹ sư SRE, bạn cần đặc biệt chú ý đến 4 chỉ số vàng:

1. **`http_reqs` (Throughput / Lưu lượng):**
   - Tổng số request HTTP đã gửi thành công và tốc độ xử lý trung bình trên giây (`requests/s`).
2. **`http_req_duration` (Độ trễ phản hồi):**
   - **avg (Trung bình):** Thường không phản ánh đúng thực tế vì bị kéo xuống bởi phần lớn request nhanh.
   - **p(90) / p(95) / p(99) (Bách phân vị):** `p(95) = 28ms` nghĩa là 95% số request người dùng nhận được phản hồi trong vòng 28ms hoặc nhanh hơn, chỉ có 5% số request chậm hơn mốc này. Trong SRE, cam kết SLA/SLO luôn được tính dựa trên p95 hoặc p99.
3. **`http_req_failed` (Tỷ lệ lỗi):**
   - Tỷ lệ phần trăm các request thất bại (trả về mã 4xx hoặc 5xx). Ở điều kiện Baseline bình thường, con số này phải bằng `0.00%`.
4. **`vus` & `vus_max` (Người dùng ảo đồng thời):**
   - Số lượng luồng worker chạy đồng thời để sinh tải.

---

### 2. Thực Thi Kịch Bản Baseline & Xuất Báo Cáo JSON

Chạy kịch bản Baseline đồng thời yêu cầu k6 xuất kết quả phân tích dạng JSON ra tệp `/root/load-test-lab/reports/baseline-summary.json`:

```bash
k6 run --summary-export=/root/load-test-lab/reports/baseline-summary.json /root/load-test-lab/scripts/load-baseline.js
```

Quá trình chạy sẽ diễn ra trong khoảng 15 giây. Quan sát trên terminal:
- Số request/s tăng dần và duy trì ổn định.
- `http_req_duration` p(95) duy trì ở mức thấp (< 50ms).
- `http_req_failed` đạt 0.00%.

---

### 3. Phân Tích Dữ Liệu Báo Cáo Với `jq`

Dùng lệnh `jq` để trích xuất nhanh các chỉ số cốt lõi từ tệp báo cáo JSON vừa xuất:

```bash
cat /root/load-test-lab/reports/baseline-summary.json | jq '{
  total_requests: .metrics.http_reqs.values.count,
  throughput_rps: .metrics.http_reqs.values.rate,
  latency_p95_ms: .metrics.http_req_duration.values["p(95)"],
  latency_avg_ms: .metrics.http_req_duration.values.avg,
  error_rate: .metrics.http_req_failed.values.rate
}'
```

*Ví dụ kết quả mẫu:*
```json
{
  "total_requests": 1284,
  "throughput_rps": 85.3,
  "latency_p95_ms": 32.4,
  "latency_avg_ms": 22.1,
  "error_rate": 0
}
```

Đây chính là **Đường cơ sở (Baseline)** của hệ thống khi chạy bình thường.

Sau khi đã xuất thành công tệp `baseline-summary.json`, nhấn **Check** để hoàn thành Bước 2!
