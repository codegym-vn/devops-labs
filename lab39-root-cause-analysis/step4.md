# Bước 4: Hotfix Phục Hồi Dịch Vụ & Đánh Giá Post-Mortem

Bạn đã có đầy đủ bằng chứng khoa học từ Tracing và Logging:
- **Thủ phạm**: `payment-service`
- **Nguyên nhân cốt lõi**: `DB_POOL_MAX=2` trong tệp cấu hình môi trường gây cạn kiệt hồ chứa kết nối (Connection Pool Exhaustion).

Bây giờ là thời khắc quyết định của kỹ sư On-Call: **Khắc phục sự cố (Hotfix), khôi phục dịch vụ cho khách hàng (MTTR) và hoàn tất báo cáo sự cố (Post-Mortem)**.

---

### 1. Thực Hiện Hotfix Cấu Hình

Hãy cập nhật tệp **/root/incident-lab/payment-service.env**, điều chỉnh `DB_POOL_MAX` từ `2` lên `20` để đáp ứng lưu lượng truy cập đồng thời:

```bash
sed -i 's/DB_POOL_MAX=2/DB_POOL_MAX=20/' /root/incident-lab/payment-service.env
cat /root/incident-lab/payment-service.env
```

Khởi động lại **Payment Service** để nạp cấu hình mới:

```bash
/root/incident-lab/restart-payment-service.sh
```

---

### 2. Kiểm Thử Phục Hồi Dịch Vụ (Service Verification)

Sau khi khởi động lại, hãy gửi liên tục nhiều giao dịch đặt hàng đồng thời để kiểm chứng hệ thống đã hoàn toàn thoát khỏi tình trạng nghẽn:

```bash
for i in {1..5}; do
  curl -s -o /dev/null -w "Request $i -> HTTP_CODE: %{http_code} | TIME: %{time_total}s\n" \
    -X POST http://localhost/api/checkout \
    -H "Content-Type: application/json" \
    -d "{\"item\":\"MacBook Pro M3\",\"amount\":2200}" &
done
wait
```

**Kết quả kỳ vọng:**
- Toàn bộ các request đều phản hồi **HTTP 200**!
- Tỷ lệ lỗi 504 hoàn toàn biến mất.
- Dung lượng Pool (20) đủ lớn để luân chuyển kết nối ngay lập tức mà không có request nào bị kẹt trong hàng đợi.

---

### 3. Lập Báo Cáo Sự Cố Chuẩn SRE (Blameless Post-Mortem)

Trong văn hóa SRE chuẩn mực, việc khôi phục dịch vụ chỉ hoàn thành 50% trách nhiệm. 50% còn lại là phương pháp **5 Whys (Năm câu hỏi tại sao)** và **Action Items (Hành động phòng ngừa)** để lỗi này vĩnh viễn không bao giờ tái diễn.

Hãy tạo tệp báo cáo hậu sự cố tại **/root/incident-report/post-mortem.md**:

```bash
cat << 'EOF' > /root/incident-report/post-mortem.md
# Incident Post-Mortem: Checkout Service Latency Spike & 504 Outage

## 1. Tóm tắt sự cố (Summary)
- Thời gian: 02:15 AM
- Mức độ nghiêm trọng: P1 (Critical Outage)
- Tác động: 38% giao dịch đặt hàng bị thất bại do lỗi 504 Gateway Timeout.

## 2. Phân tích 5 Whys (Root Cause Analysis)
1. Tại sao khách hàng nhận lỗi 504 Gateway Timeout?
   -> Do Order Service gọi sang Payment Service bị timeout sau 2000ms.
2. Tại sao Payment Service bị trễ và không phản hồi kịp?
   -> Do request bị kẹt ở công đoạn xin kết nối Database (db_acquire_connection).
3. Tại sao công đoạn xin kết nối lại bị treo quá 2000ms?
   -> Do Connection Pool bị cạn kiệt (ConnectionPoolExhaustedError).
4. Tại sao Connection Pool lại cạn kiệt nhanh chóng khi có tải đồng thời?
   -> Do cấu hình kích thước hồ chứa kết nối tối đa chỉ được đặt là DB_POOL_MAX=2.
5. Tại sao tham số môi trường Production lại chỉ có 2 kết nối?
   -> Do cấu hình copy nguyên bản từ môi trường thử nghiệm cá nhân (Local Dev) mà không có khâu thẩm định tải (Capacity Planning) và cấu hình biến môi trường trước khi đưa lên Production.

## 3. Hành động khắc phục & phòng ngừa (Action Items)
- [Đã xong] Hotfix tăng DB_POOL_MAX=20 trên Payment Service.
- [Cần làm] Thiết lập Prometheus Alert cảnh báo khi tỷ lệ chiếm dụng Connection Pool vượt quá 80%.
- [Cần làm] Đưa quy trình Capacity Planning vào Security/Config Gate của CI/CD Pipeline.
EOF
```

---

### 4. Đánh Giá Tự Động

Sau khi hoàn tất cả 2 việc (Hotfix dịch vụ và tạo báo cáo Post-Mortem), hãy nhấn **Check**. Script kiểm tra sẽ tự động bắn một loạt request đồng thời vào hệ thống để xác thực độ ổn định thực tế.
