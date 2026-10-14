# Hoàn Thành Xuất Sắc Lab 42: Xây Dựng Monitoring Dashboard Với Grafana!

Chúc mừng bạn đã hoàn thành bài thực hành chuyên sâu về **Visual Observability** và làm chủ kỹ năng xây dựng hệ thống giám sát tập trung chuẩn Production bằng **Grafana**.

---

## Những Năng Lực Cốt Lõi Bạn Đã Thu Nhận

1. **Dashboard as Code (Provisioning):** Thoát ly hoàn toàn khỏi thói quen bấm chuột thủ công (ClickOps). Bạn đã cấu hình nguồn dữ liệu Prometheus (`datasources`) và quản lý các Dashboard (`providers`) hoàn toàn thông qua mã nguồn YAML/JSON được lưu trữ và kiểm soát phiên bản trong Git.
2. **Kỹ Năng Trực Quan Hóa Đa Chiều:**
   - Sử dụng **Gauge Panel** kèm dải ngưỡng màu sinh động để phản ánh tỷ lệ tải CPU và RAM máy chủ tức thời.
   - Sử dụng **Stat Panel** nổi bật với mini-sparkline theo dõi người dùng trực tuyến và tỷ lệ lỗi 5xx.
   - Sử dụng **Time-Series Panel** hiển thị xu hướng biến thiên thông lượng mạng và lưu lượng API.
3. **Mô Hình RED Thực Chiến:** Triển khai bảng điều khiển giám sát ứng dụng Microservices theo đúng chuẩn SRE quốc tế: **Rate (RPS) - Errors (5xx %) - Duration (p95 SLA)**.
4. **Dynamic Templating (Variables):** Sử dụng hàm `label_values()` biến một dashboard tĩnh thành một hệ thống giám sát linh hoạt, cho phép người dùng lọc số liệu theo từng API Endpoint hoặc dịch vụ chỉ với một cú nhấp chuột.

---

## Bảng Nguyên Tắc Vàng Khi Thiết Kế Dashboard SRE

| Tiêu chuẩn | Thực hành khuyến nghị | Lý do kỹ thuật |
| :--- | :--- | :--- |
| **Quy tắc 5 giây** | Đặt các chỉ số tổng quan (Stat/Gauge) ở hàng trên cùng | Kỹ sư On-Call chỉ cần 5 giây để nhận biết hệ thống bình thường hay có sự cố |
| **Giới hạn số lượng Panel** | Không vượt quá 15-20 panel trên một trang | Tránh làm quá tải trình duyệt và giảm bớt số lượng truy vấn đè nặng lên Prometheus TSDB |
| **Quy chuẩn màu sắc** | Xanh (Bình thường), Vàng (Nguy cơ), Đỏ (Báo động) | Tạo phản xạ thị giác thống nhất cho toàn bộ đội ngũ kỹ thuật |
| **Độ phân giải thời gian** | Mặc định để `refresh: 5s` hoặc `10s` | Tránh đặt refresh quá dày (1s) gây nghẽn mạng nội bộ và CPU của Prometheus |

---

## Hướng Đi Tiếp Theo

Bạn đã có dữ liệu (Lab 40), câu truy vấn phân tích (Lab 41), và giao diện trực quan hóa (Lab 42). Mảnh ghép cuối cùng để hoàn thiện vòng tròn Observability chính là:
**"Lab 43: Thiết Lập Cảnh Báo Với Prometheus Alertmanager"** — tự động hóa phát hiện sự cố và gửi thông báo khẩn cấp tới Slack, Telegram, Email và Webhook khi hệ thống vượt ngưỡng an toàn!
