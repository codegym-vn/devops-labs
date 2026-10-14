# Bước 3: Đẩy Tải Tới Ngưỡng Bão Hòa & Xác Định Nút Thắt Cổ Chai (Bottleneck)

Trong bước này, bạn sẽ đóng vai trò của kỹ sư SRE điều tra sự cố: sử dụng kịch bản `load-spike.js` để ép tải hệ thống vượt quá giới hạn thiết kế (tăng vọt lên 85 VUs), đồng thời quan sát phản ứng chuỗi (Chain Reaction) trên Grafana Dashboard để xác định chính xác nguyên nhân gốc rễ (Root Cause) gây nghẽn.

---

### 1. Thực Thi Kịch Bản Ép Tải Đột Biến: `load-spike.js`

Kịch bản `load-spike.js` được thiết kế theo 3 giai đoạn:
- **0 - 10s:** Tải ban đầu 25 VUs (vùng an toàn).
- **10s - 30s:** Đẩy tải đột biến lên **85 VUs** (vượt ngưỡng chịu tải).
- **30s - 45s:** Hạ nhiệt về 10 VUs để kiểm tra khả năng phục hồi.

Chạy kịch bản và xuất kết quả k6 ra tệp `/root/load-monitoring-lab/reports/spike-summary.json`:

```bash
k6 run --summary-export=/root/load-monitoring-lab/reports/spike-summary.json /root/load-monitoring-lab/scripts/load-spike.js
```

---

### 2. Quan Sát "Phản Ứng Dây Chuyền" Trên Grafana

Trong quá trình lệnh trên đang thực thi (đặc biệt từ giây thứ 15 đến 30), hãy chuyển sang màn hình Grafana Dashboard:

1. **Giai đoạn Chạm Trần (Saturation):**
   - **Active Connections:** Tăng vọt lên > 80 kết nối.
   - **Server CPU Saturation:** Kim đồng hồ vọt thẳng vào **Vùng Đỏ** (> 85% - 95%).
2. **Hệ Quả Về Độ Trễ (Latency Spike):**
   - Panel **Average Response Latency** nhảy dựng đứng từ mức 30ms lên hơn **400ms - 600ms**.
3. **Hệ Quả Về Lỗi Hệ Thống (Errors):**
   - Khi CPU và Thread Pool bị cạn kiệt, hàng đợi request bị tràn.
   - Panel **HTTP Error Rate (%)** bắt đầu xuất hiện gai nhọn (Spike) của mã lỗi `503 Service Unavailable`, đồng thời đường **Pool Exhausted Events** nhảy số.
4. **Giai đoạn Tự Phục Hồi (Self-Healing):**
   - Khi k6 bước vào giai đoạn ramp-down (hạ tải về 10 VUs), CPU giảm nhanh về mức an toàn, độ trễ hạ nhiệt và tỷ lệ lỗi biến mất.

---

### 3. Đối Chiếu PromQL Tìm Nút Thắt Cổ Chai

Chạy lệnh sau để truy vấn số lượng sự cố bão hòa tài nguyên mà Prometheus đã ghi nhận được trong đợt thử nghiệm vừa rồi:

```bash
curl -s 'http://localhost:9090/api/v1/query?query=app_thread_pool_exhausted_total' | jq -r '.data.result[0].value[1]'
```

*Phân tích kết quả SRE:*
Nút thắt cổ chai không nằm ở mạng (Network) hay dung lượng RAM, mà nằm ở **Năng lực tính toán của CPU và kích thước Thread Pool phục vụ tác vụ đặt hàng (`POST /api/orders`)**. Khi số lượng kết nối đồng thời vượt qua mốc 60 VUs, CPU đạt mức bão hòa > 85%, dẫn đến suy sụp dây chuyền về độ trễ và lỗi 503.

Sau khi kịch bản k6 chạy xong và xuất tệp `spike-summary.json`, nhấn **Check** để hoàn thành Bước 3!
