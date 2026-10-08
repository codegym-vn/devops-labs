# Bước 4: Sinh Tải Tự Động & Thực Thi Truy Vấn PromQL

Sau khi hệ thống giám sát đã sẵn sàng, chúng ta sẽ tạo lưu lượng truy cập thực tế mô phỏng người dùng và sử dụng ngôn ngữ truy vấn **PromQL (Prometheus Query Language)** để tính toán các chỉ số vàng (Golden Signals) của dịch vụ: Thông lượng (Rate), Tỷ lệ lỗi (Errors) và Độ trễ (Duration/Latency).

---

### 1. Tạo script sinh tải lưu lượng tự động

Tạo và chạy script `generate-traffic.sh` gửi liên tục các HTTP request đến cả 2 endpoint `/api/orders` (thành công) và `/api/checkout` (có độ trễ và phát sinh lỗi 500 ngẫu nhiên):

```bash
cd /root/app-monitoring-lab
cat << 'EOF' > generate-traffic.sh
#!/bin/bash
echo "Dang sinh luu luong HTTP den ung dung trong 15 giay..."
for i in {1..70}; do
  curl -s http://localhost:3000/api/orders > /dev/null &
  if [ $((i % 3)) -eq 0 ]; then
    curl -s -X POST http://localhost:3000/api/checkout > /dev/null &
  fi
  sleep 0.2
done
wait
echo "Hoan tat sinh luu luong."
EOF
chmod +x generate-traffic.sh
./generate-traffic.sh
```{{exec}}

Đợi 6 giây để Prometheus hoàn thành chu kỳ kéo số liệu mới nhất:

```bash
sleep 6
```{{exec}}

---

### 2. Truy vấn Thông lượng xử lý (Requests Per Second - RPS)

Hàm **rate()** tính toán tốc độ tăng trung bình trên mỗi giây của một Counter trong khoảng thời gian xác định (ví dụ 1 phút `[1m]`):

```bash
curl -s -G --data-urlencode 'query=sum(rate(http_requests_total[1m]))' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: .metric, rps: .value[1]}'
```{{exec}}

Giá trị **rps** thể hiện số lượng request trên giây mà dịch vụ đang phục vụ.

---

### 3. Tính toán Tỷ lệ lỗi hệ thống (Error Rate Percentage)

Lấy tỷ lệ của các request có mã lỗi 500 chia cho tổng số request, sau đó nhân 100 để tính tỷ lệ phần trăm:

```bash
curl -s -G --data-urlencode 'query=(sum(rate(http_requests_total{status_code="500"}[1m])) / sum(rate(http_requests_total[1m]))) * 100' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "Error Rate %", percentage: .value[1]}'
```{{exec}}

Chỉ số này là căn cứ trực tiếp để thiết lập cảnh báo tự động (Alerting Rule) cho đội ngũ trực vận hành khi tỷ lệ lỗi vượt ngưỡng cho phép (ví dụ vượt quá 5%).

---

### 4. Tính toán Độ trễ phân vị p95 (95th Percentile Latency)

Trung bình cộng (Average) không phản ánh đúng trải nghiệm của người dùng vì bị triệt tiêu bởi các giá trị ngoại lai. Trong kỹ thuật SRE, chúng ta sử dụng hàm **histogram_quantile** để xác định ngưỡng thời gian mà 95% người dùng nhận phản hồi:

```bash
curl -s -G --data-urlencode 'query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1m])) by (le))' http://localhost:9090/api/v1/query | jq '.data.result[] | {metric: "p95 Latency (seconds)", latency: .value[1]}'
```{{exec}}

Lưu kết quả phân tích PromQL ra tệp **promql-analysis.json**:

```bash
curl -s -G --data-urlencode 'query=sum(rate(http_requests_total[1m]))' http://localhost:9090/api/v1/query > promql-analysis.json
ls -lh promql-analysis.json
```{{exec}}

Nhấn **Check** để hoàn thành bài lab.
