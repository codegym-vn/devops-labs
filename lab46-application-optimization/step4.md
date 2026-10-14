# Bước 4: Kiểm Chứng Sau Tối Ưu (Benchmark After) & So Sánh Đối Chiếu

Sau khi triển khai giải pháp kỹ thuật, bước then chốt của kỹ sư hiệu năng là chạy lại đúng kịch bản tải ban đầu để thu thập số liệu **Benchmark After**, từ đó lập bảng so sánh đối chiếu định lượng (Before vs After) để chứng minh giá trị của giải pháp.

---

### 1. Thực Thi Benchmark Sau Khi Tối Ưu (After)

Chạy lại kịch bản kiểm thử tải k6 với đúng thông số cũ (20 VUs trong 15 giây) và xuất kết quả ra `/root/app-opt-lab/reports/after-summary.json`:

```bash
k6 run --summary-export=/root/app-opt-lab/reports/after-summary.json /root/app-opt-lab/scripts/benchmark.js
```

> **Lưu ý:** Chờ khoảng 15 giây cho k6 chạy xong và in ra bảng tổng hợp kết quả trên terminal.

---

### 2. Trích Xuất Dữ Liệu Benchmark After

Sử dụng lệnh `jq` để xem các chỉ số mới:

```bash
cat /root/app-opt-lab/reports/after-summary.json | jq '{
  total_requests: .metrics.http_reqs.values.count,
  throughput_rps: .metrics.http_reqs.values.rate,
  latency_p95_ms: .metrics.http_req_duration.values["p(95)"],
  latency_avg_ms: .metrics.http_req_duration.values.avg,
  error_rate: .metrics.http_req_failed.values.rate
}'
```

---

### 3. Khởi Tạo Báo Cáo So Sánh Định Lượng Before / After

Tạo tệp báo cáo tổng kết so sánh tại `/root/app-opt-lab/reports/optimization-comparison.json`:

```bash
cat << 'EOF' > /root/app-opt-lab/reports/optimization-comparison.json
{
  "service": "CATALOG-API-SERVICE",
  "optimization_technique": "CACHE_ASIDE_PATTERN",
  "benchmark_comparison": {
    "before_optimization": {
      "cache_status": "DISABLED (BYPASS)",
      "throughput_rps": 65.4,
      "latency_p95_ms": 385.2,
      "status": "BOTTLENECK_DETECTED"
    },
    "after_optimization": {
      "cache_status": "ENABLED (CACHE_HIT)",
      "throughput_rps": 380.5,
      "latency_p95_ms": 8.5,
      "status": "OPTIMIZED"
    },
    "improvement_factor": {
      "throughput_multiplier": "5.8x Increase",
      "latency_reduction_percent": "97.8% Faster"
    }
  },
  "verified_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
cat /root/app-opt-lab/reports/optimization-comparison.json | jq .
```

*Đánh giá kết quả:*
* **Throughput:** Tăng từ ~65 RPS lên ~380 RPS (gấp gần 6 lần).
* **Latency p95:** Giảm sâu từ ~385ms xuống còn dưới 10ms (nhanh hơn 97%).
* **Chi phí phần cứng:** $0 (hoàn toàn nhờ tối ưu hóa tầng ứng dụng).

Sau khi tệp `optimization-comparison.json` đã được tạo xong, nhấn **Check** để hoàn thành toàn bộ bài Lab 46!
