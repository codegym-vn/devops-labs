# Bước 1: Tiếp Nhận Incident & Triage Hiện Trường

Hệ thống giám sát vừa phát lệnh báo động khẩn cấp. Là người trực On-Call, phản xạ đầu tiên của bạn là **Triage (Phân loại & Khảo sát hiện trường)** nhằm xác định chính xác triệu chứng, mức độ ảnh hưởng và phạm vi sự cố.

Tuyệt đối không đưa ra kết luận cảm tính khi chưa thu thập dữ liệu thực tế!

---

### 1. Thử Thách Khảo Sát Hiện Trường Bằng Lệnh

Endpoint tiếp nhận giao dịch của khách hàng là:
```text
POST http://localhost/api/checkout
Content-Type: application/json
Body: {"item":"iPhone 16 Pro Max","amount":1599}
```

Hãy sử dụng các công cụ dòng lệnh (`curl`, `time`, `http`) để tự trả lời các câu hỏi sau:

1. **Request thực tế mất bao nhiêu thời gian để phản hồi?**
   *(Gợi ý: Dùng cờ `-w` trong `curl` để đo `time_total` và `http_code`, hoặc lệnh `time`)*
2. **Mã trạng thái HTTP (Status Code) trả về là gì?**
   *(Là 200, 500, 502, 503 hay 504?)*
3. **Các thành phần hạ tầng có bị sập hoàn toàn (Crash/Down) hay không?**
   *(Kiểm tra container qua `docker ps`, kiểm tra endpoint `/health` của Nginx port 80, Order Service port 3001, và Payment Service port 3002)*.

> [!TIP]
> Bạn có thể đo đạc chính xác thời gian và mã trạng thái của một request bằng mẫu lệnh sau:
> ```bash
> curl -s -o /dev/null -w "HTTP_CODE: %{http_code} | TOTAL_TIME: %{time_total}s\n" \
>   -X POST http://localhost/api/checkout \
>   -H "Content-Type: application/json" \
>   -d '{"item":"iPhone 16 Pro Max","amount":1599}'
> ```

---

### 2. Hiện Tượng Bạn Quan Sát Được

Khi gửi request, bạn sẽ nhận thấy:
- **Tất cả các service đều đang sống (UP)** khi kiểm tra endpoint `/health`. Không có container nào bị thoát (Exit 1).
- Nhưng khi gửi giao dịch đặt hàng thật, request bị **treo đơ hơn 2 giây**, sau đó Nginx trả về mã lỗi **504 Gateway Timeout** hoặc **500 Internal Error**.
- Điều này loại trừ giả thiết "hạ tầng chết". Hệ thống đang mắc kẹt trong tình trạng **Cascading Latency (Trễ dây chuyền)** do một dịch vụ cấp sâu không phản hồi kịp thời.

---

### 3. Yêu Cầu Hoàn Thành Bước 1

Để hệ thống ghi nhận bạn đã hoàn thành giai đoạn Triage, hãy ghi lại báo cáo khảo sát sơ bộ vào tệp **/root/incident-report/step1-triage.txt** với nội dung chuẩn hóa như sau:

```bash
cat << 'EOF' > /root/incident-report/step1-triage.txt
TARGET_ENDPOINT=http://localhost/api/checkout
OBSERVED_STATUS_CODE=504
INCIDENT_SEVERITY=P1
PRIMARY_SYMPTOM=HIGH_LATENCY_TIMEOUT
EOF
```

Sau khi tạo tệp báo cáo, hãy nhấn nút **Check** (hoặc chuyển sang bước kế tiếp) để hệ thống tự động đánh giá kết quả khảo sát của bạn.
