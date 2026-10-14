# Bước 2: Đo Lường Hiệu Năng Ban Đầu Dưới Tải Cao (Benchmark Before)

Trong bước này, bạn sẽ sử dụng k6 để gửi đồng thời **80 Virtual Users (VUs)** qua Nginx tới backend trong vòng 15 giây nhằm kiểm chứng giới hạn chịu tải ban đầu và ghi lại số liệu Benchmark Before.

---

### 1. Thực Thi Kịch Bản Ép Tải Cao

Chạy kịch bản kiểm thử tải qua Nginx và xuất kết quả ra `/root/infra-opt-lab/reports/before-summary.json`:

```bash
k6 run --summary-export=/root/infra-opt-lab/reports/before-summary.json /root/infra-opt-lab/scripts/stress-high.js
```

> **Lưu ý:** Lệnh `k6 run` sẽ chạy trong khoảng 15 giây. Hãy chờ cho đến khi terminal in ra toàn bộ bảng thống kê kết quả của k6.

---

### 2. Quan Sát Lỗi Xuất Hiện Do Nghẽn Hạ Tầng

Ngay khi số lượng VU đạt mức 80 (vượt quá giới hạn `worker_connections 64` của Nginx), bạn sẽ thấy trên terminal bắt đầu xuất hiện các dòng lỗi đỏ:
* Các check `status is 200` bị fail liên tiếp.
* Chỉ số `http_req_failed` tăng vọt lên khoảng **10% - 30%**.

Kiểm tra nhật ký lỗi (error log) của Nginx để xác nhận nguyên nhân:

```bash
docker logs nginx-proxy 2>&1 | tail -n 15
```

Bạn sẽ thấy thông báo lỗi kinh điển của Nginx:
```text
[alert] 1#1: 64 worker_connections are not enough while connecting to upstream
```
Thông báo này chứng minh rõ ràng: lỗi không phải do code của backend bị sập, mà do Nginx bị cạn kiệt tài nguyên kết nối kết hợp với việc phải mở/đóng socket liên tục không có KeepAlive!

---

### 3. Trích Xuất Dữ Liệu Benchmark Before Bằng `jq`

Sử dụng lệnh `jq` để ghi lại hiện trạng trước khi tối ưu:

```bash
cat /root/infra-opt-lab/reports/before-summary.json | jq '{
  total_requests: .metrics.http_reqs.values.count,
  failed_requests: .metrics.http_req_failed.values.passes,
  failure_rate_percent: ((.metrics.http_req_failed.values.rate * 10000 | round) / 100),
  latency_p95_ms: .metrics.http_req_duration.values["p(95)"]
}'
```

*Số liệu ghi nhận:* Tỷ lệ lỗi thất bại lên tới hàng trăm request (chiếm 15% - 25% tổng lưu lượng).

Sau khi có tệp `before-summary.json`, nhấn **Check** để hoàn thành Bước 2!
