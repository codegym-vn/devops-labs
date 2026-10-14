# Bước 2: Đo Lường Hiệu Năng Ban Đầu (Benchmark Before)

Trước khi thực hiện bất kỳ thay đổi nào vào cấu hình hoặc mã nguồn, bạn phải chạy bài đo lường hiệu năng chuẩn hóa (**Benchmark Before**) để ghi lại các chỉ số làm mốc tham chiếu so sánh sau này.

---

### 1. Khảo Sát Kịch Bản Kiểm Thử Tải: `benchmark.js`

Mở tệp kịch bản kiểm thử tải tại `/root/app-opt-lab/scripts/benchmark.js`:

```bash
cat /root/app-opt-lab/scripts/benchmark.js
```

Kịch bản được thiết lập để mô phỏng **20 người dùng ảo (VUs)** truy cập liên tục vào danh mục sản phẩm `/api/catalog` trong vòng **15 giây**.

---

### 2. Thực Thi Benchmark Trước Khi Tối Ưu (Before)

Thực thi kịch bản k6 và xuất kết quả ra tệp `/root/app-opt-lab/reports/before-summary.json`:

```bash
k6 run --summary-export=/root/app-opt-lab/reports/before-summary.json /root/app-opt-lab/scripts/benchmark.js
```

> **Lưu ý:** Lệnh `k6 run` sẽ chạy trong khoảng 15 giây. Hãy chờ cho đến khi terminal in ra toàn bộ bảng thống kê kết quả của k6 rồi mới thực hiện bước trích xuất dữ liệu tiếp theo.

---

### 3. Trích Xuất Dữ Liệu Benchmark Before

Sau khi k6 hoàn tất, sử dụng lệnh `jq` để trích xuất các chỉ số đường cơ sở:

```bash
cat /root/app-opt-lab/reports/before-summary.json | jq '{
  total_requests: .metrics.http_reqs.values.count,
  throughput_rps: .metrics.http_reqs.values.rate,
  latency_p95_ms: .metrics.http_req_duration.values["p(95)"],
  latency_avg_ms: .metrics.http_req_duration.values.avg,
  error_rate: .metrics.http_req_failed.values.rate
}'
```

*Số liệu ghi nhận thực tế trước khi tối ưu:*
* **Throughput (RPS):** Chỉ đạt khoảng **50 - 75 requests/s** (rất thấp đối với một API đọc danh mục).
* **Latency p95:** Dao động từ **300ms đến 450ms** (quá chậm so với tiêu chuẩn trải nghiệm người dùng hiện đại).

Số liệu này chính là bằng chứng xác thực rằng hệ thống đang bị nghẽn nghiêm trọng ở tầng ứng dụng.

Sau khi tệp `before-summary.json` đã được tạo và chứa dữ liệu hợp lệ, nhấn **Check** để hoàn thành Bước 2!
