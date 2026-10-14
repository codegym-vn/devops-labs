# Bước 4: Kiểm Chứng Sau Tối Ưu (Benchmark After) & Nghiệm Thu

Sau khi đã nạp cấu hình KeepAlive và mở rộng giới hạn worker connections, bạn sẽ thực thi lại đúng kịch bản ép tải 80 VUs ban đầu để kiểm chứng rằng hiện tượng rớt kết nối đã được giải quyết hoàn toàn.

---

### 1. Thực Thi Benchmark Sau Khi Tối Ưu (After)

Chạy lại kịch bản kiểm thử tải k6 và xuất kết quả ra `/root/infra-opt-lab/reports/after-summary.json`:

```bash
k6 run --summary-export=/root/infra-opt-lab/reports/after-summary.json /root/infra-opt-lab/scripts/stress-high.js
```

> **Lưu ý:** Lệnh `k6 run` sẽ chạy trong khoảng 15 giây. Hãy chờ cho đến khi terminal in ra toàn bộ bảng thống kê kết quả của k6.

---

### 2. Quan Sát Sự Biến Chuyển Của Hệ Thống

Khác hoàn toàn với lần chạy ở Bước 2, kết quả lần này sẽ cho thấy:
* **Tỷ lệ pass:** Đạt **100.00%** (không còn bất kỳ request nào bị fail).
* **Tỷ lệ lỗi (`http_req_failed`):** Giảm hoàn toàn về **`0.00%`**.
* **Throughput (RPS):** Tăng vọt lên gấp 2 đến 3 lần vì Nginx không còn mất thời gian mở/đóng TCP socket liên tục.

---

### 3. Trích Xuất Dữ Liệu Benchmark After Bằng `jq`

Xem các chỉ số đã được cải thiện sau khi tối ưu:

```bash
cat /root/infra-opt-lab/reports/after-summary.json | jq '{
  total_requests: .metrics.http_reqs.values.count,
  failed_requests: .metrics.http_req_failed.values.passes,
  failure_rate_percent: ((.metrics.http_req_failed.values.rate * 10000 | round) / 100),
  throughput_rps: .metrics.http_reqs.values.rate,
  latency_p95_ms: .metrics.http_req_duration.values["p(95)"]
}'
```

---

### 4. Khởi Tạo Báo Cáo Nghiệm Thu Tối Ưu Hạ Tầng

Tạo tệp báo cáo tổng kết tại `/root/infra-opt-lab/reports/infra-tuning-report.json`:

```bash
cat << 'EOF' > /root/infra-opt-lab/reports/infra-tuning-report.json
{
  "audit_target": "NGINX-REVERSE-PROXY-INFRASTRUCTURE",
  "tuning_parameters": {
    "nginx": {
      "worker_connections": "Increased from 64 to 4096",
      "upstream_keepalive": "Enabled with 64 persistent sockets",
      "proxy_protocol": "HTTP/1.1 with persistent connection headers"
    },
    "linux_kernel": {
      "net.core.somaxconn": 4096,
      "net.ipv4.tcp_max_syn_backlog": 4096,
      "net.ipv4.ip_local_port_range": "10240 65535"
    }
  },
  "results_comparison": {
    "connection_drops_before": "High failure rate (15% - 25% errors)",
    "connection_drops_after": "0.00% Error Rate (Zero drops)",
    "system_resilience": "STABLE_UNDER_HEAVY_CONCURRENCY"
  },
  "verified_at": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF
cat /root/infra-opt-lab/reports/infra-tuning-report.json | jq .
```

Sau khi tệp `infra-tuning-report.json` đã được tạo xong, nhấn **Check** để hoàn thành toàn bộ bài Lab 47!
