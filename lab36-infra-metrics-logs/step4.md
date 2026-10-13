# Bước 4: Mô Phỏng Sự Kiện Hạ Tầng & Truy Vấn Log Bằng LogQL

Trong vận hành thực tế, khi nhận được cảnh báo về tài nguyên phần cứng (CPU cao, Disk đầy), kỹ sư DevOps cần lập tức điều tra log hệ thống để xác định ngữ cảnh sự cố. Trong bước này, bạn sẽ mô phỏng các sự kiện sự cố hạ tầng và sử dụng ngôn ngữ **LogQL (Loki Query Language)** để điều tra, bóc tách và phân tích dữ liệu.

---

### 1. Tạo script mô phỏng sự kiện hạ tầng thực tế

Tạo kịch bản **simulate-infra-events.sh** để ghi các bản ghi sự cố mô phỏng vào thư mục **/var/log/infrastructure**:

```bash
cd /root/infra-monitoring-lab
cat << 'EOF' > simulate-infra-events.sh
#!/bin/bash
TARGET_LOG="/var/log/infrastructure/system.log"

echo "Dang ghi nhan cac su kien ha tang vao $TARGET_LOG..."

# 1. Canh bao dung luong o dia vuot nguong toi han
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=storage-monitor: [CRITICAL] Filesystem /dev/sda1 utilization at 96%! Threshold 90% exceeded." >> "$TARGET_LOG"

# 2. Su co bo nho tran dan den OOM Killer can thiep
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=kernel: [ERROR] Out of memory: Kill process 4821 (memory-heavy-job) score 850 or sacrifice child." >> "$TARGET_LOG"

# 3. Dau hieu tan cong do quet mat khau SSH (Brute Force)
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=sshd: [WARNING] Failed password for root from 192.168.1.150 port 55102 ssh2" >> "$TARGET_LOG"
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=sshd: [WARNING] Failed password for admin from 192.168.1.150 port 55104 ssh2" >> "$TARGET_LOG"
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=sshd: [ERROR] Maximum authentication attempts exceeded for root from 192.168.1.150" >> "$TARGET_LOG"

# 4. Tien trinh duoc khoi phuc boi Watchdog
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") host=srv-prod-01 component=systemd: [INFO] Service memory-heavy-job restarted cleanly by watchdog." >> "$TARGET_LOG"

echo "Da ghi nhan thanh cong 6 su kien ha tang moi."
EOF
chmod +x simulate-infra-events.sh
./simulate-infra-events.sh
```{{exec}}

Chờ 5 giây để Promtail đồng bộ các dòng nhật ký mới về Loki:

```bash
sleep 5
```{{exec}}

---

### 2. Thực thi các truy vấn LogQL điều tra sự cố

Cú pháp **LogQL** được thiết kế tương đồng với PromQL, kết hợp giữa bộ lọc nhãn (Stream Selector) và bộ lọc dòng văn bản (Line Filters):

* **|= "chuỗi"**: Lọc các dòng có chứa chuỗi văn bản.
* **!= "chuỗi"**: Loại bỏ các dòng có chứa chuỗi văn bản.
* **|~ "regex"**: So khớp theo biểu thức chính quy (Regular Expression).

#### A. Truy vấn toàn bộ dòng log của Stream hạ tầng

```bash
curl -s -G --data-urlencode 'query={job="infrastructure"}' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

#### B. Lọc các sự cố mức độ nghiêm trọng [CRITICAL]
Tìm kiếm tức thì các sự cố cạn kiệt tài nguyên:

```bash
curl -s -G --data-urlencode 'query={job="infrastructure"} |= "CRITICAL"' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

#### C. Lọc bằng biểu thức chính quy đa điều kiện
Truy vết các sự kiện liên quan đến mật khẩu SSH thất bại hoặc lỗi bộ nhớ OOM:

```bash
curl -s -G --data-urlencode 'query={job="infrastructure"} |~ "(Failed password|Out of memory)"' http://localhost:3100/loki/api/v1/query_range | jq '.data.result[].values[][1]'
```{{exec}}

---

### 3. Kỹ thuật Log-to-Metrics: Đếm tần suất lỗi từ Log

Trong Observability, kỹ sư không chỉ đọc log mà còn chuyển đổi log thành số liệu định lượng (Metrics) để phát hiện xu hướng bất thường. Hàm **count_over_time** tính toán tổng số dòng log thỏa mãn điều kiện lọc trong khung thời gian xác định (ví dụ trong vòng 1 giờ qua **[1h]**):

```bash
curl -s -G --data-urlencode 'query=count_over_time({job="infrastructure"} |= "ERROR" [1h])' http://localhost:3100/loki/api/v1/query | jq '.data.result[] | {metric: .metric, error_occurrences: .value[1]}'
```{{exec}}

---

### 4. Xuất báo cáo tổng hợp hệ thống quan sát hạ tầng

Lưu trữ kết quả truy vấn các sự kiện CRITICAL ra tệp báo cáo **infra-observability-summary.json**:

```bash
curl -s -G --data-urlencode 'query={job="infrastructure"} |= "CRITICAL"' http://localhost:3100/loki/api/v1/query_range > /root/infra-monitoring-lab/infra-observability-summary.json
cat /root/infra-monitoring-lab/infra-observability-summary.json | jq .
```{{exec}}

Nhấn **Check** để hoàn thành bài lab.
