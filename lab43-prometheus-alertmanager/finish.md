# Hoàn Thành Xuất Sắc Lab 43: Thiết Lập Cảnh Báo (Alerting)!

Chúc mừng bạn đã hoàn thành bài thực hành chuyên sâu về **Hệ thống Cảnh báo tự động chuẩn SRE** kết hợp giữa Prometheus và Alertmanager!

---

## Những Năng Lực Cốt Lõi Bạn Đã Làm Chủ

1. **Thiết Kế Alerting Rules Bằng PromQL:** Nắm vững cấu trúc khai báo một Alert chuẩn quốc tế gồm biểu thức toán tử nhị phân, khoảng trễ chống chập chờn (`for`), nhãn phân loại (`severity`, `tier`) và chú thích hướng dẫn xử lý (`runbook_url`).
2. **Kỹ Thuật Linting Tự Động:** Sử dụng thành thạo bộ đôi công cụ dòng lệnh **`promtool`** và **`amtool`** để kiểm thử cú pháp YAML trước khi triển khai, ngăn chặn tuyệt đối lỗi cú pháp làm sập tiến trình giám sát.
3. **Làm Chủ Cây Định Tuyến (Routing Tree):** Cấu hình phân luồng thông minh dựa trên độ nghiêm trọng của sự cố, gom cụm thông báo bằng `group_by` và kiểm soát tần suất gửi thông báo qua `group_wait`, `group_interval` và `repeat_interval`.
4. **Phòng Chống Bão Cảnh Báo (Alert Fatigue):** 
   - Ứng dụng **Inhibition Rules** để tự động tắt tiếng các cảnh báo thứ cấp khi sự cố gốc đã được phát hiện.
   - Sử dụng **Silences** để thiết lập khung giờ bảo trì có kế hoạch mà không cần xóa bỏ quy tắc giám sát.
5. **Thực Chiến Fault Injection & Tín Hiệu Resolved:** Trực tiếp kích hoạt sự cố thực tế, quan sát vòng đời chuyển trạng thái `Pending` -> `Firing` -> `Resolved` và phân tích gói tin JSON Webhook.

---

## Bảng Quy Chuẩn Vàng Khi Thiết Kế Cảnh Báo SRE

| Tiêu chuẩn | Thực hành khuyến nghị | Mục tiêu vận hành |
| :--- | :--- | :--- |
| **Quy tắc Actionable** | Mọi cảnh báo bắn ra đều phải yêu cầu con người can thiệp | Loại bỏ hoàn toàn cảnh báo "cho vui" (Informational alerts) gây chai sạn thính giác |
| **Bắt buộc có Runbook URL** | Mỗi alert rule phải gắn link hướng dẫn khắc phục cụ thể | Giúp kỹ sư On-Call mới vào ca xử lý sự cố trong vòng 5 phút mà không cần mò mẫm |
| **Thời gian trễ `for`** | Tối thiểu `30s` - `2m` cho các cảnh báo hạ tầng | Lọc bỏ 99% các hiện tượng CPU/RAM spike nhất thời không đe dọa dịch vụ |
| **Send Resolved** | Luôn bật `send_resolved: true` trên các receiver | Thông báo cho toàn đội biết sự cố đã tự hồi phục hoặc được vá xong |

---

## Chúc Mừng Bạn Đã Hoàn Thành Chuỗi Chuyên Đề: Giám Sát Với Metrics & Alerting!

Trải qua chuỗi 4 bài lab thực chiến:
1. **Lab 40:** Cấu Hình Prometheus Và Exporters
2. **Lab 41:** Phân Tích Hệ Thống Bằng PromQL
3. **Lab 42:** Xây Dựng Monitoring Dashboard
4. **Lab 43:** Thiết Lập Cảnh Báo (Alerting)

Bạn đã trang bị đầy đủ hành trang kiến thức và kỹ năng thực tế của một **SRE / DevOps Engineer** chuyên nghiệp, sẵn sàng vận hành hệ thống giám sát độ tin cậy cao trên bất kỳ nền tảng Cloud hoặc Kubernetes nào!
