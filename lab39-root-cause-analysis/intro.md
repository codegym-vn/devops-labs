# [Case Study] Phân Tích Nguyên Nhân Gốc Rễ (Root Cause Analysis)

## 🚨 Bối Cảnh Tình Huống: Báo Động Đỏ Lúc 02:15 Sáng

Bạn là kỹ sư SRE (Site Reliability Engineer) / DevOps đang trong ca trực On-Call. Đồng hồ điểm 02:15 sáng, điện thoại rung liên hồi từ hệ thống cảnh báo tự động và kênh PagerDuty:

> **[CRITICAL ALERT - P1 INCIDENT]**  
> **Service:** `E-Commerce Core Gateway`  
> **Metric:** HTTP 504 / 500 error rate spiked to **38%**, Latency p99 **> 2500ms**.  
> **Customer Impact:** Hàng nghìn người dùng tại thị trường Châu Á - Thái Bình Dương không thể hoàn tất bước thanh toán đơn hàng (Checkout). Doanh thu đang sụt giảm nghiêm trọng theo từng phút.

Đội ngũ quản lý yêu cầu khắc phục sự cố ngay lập tức (Giảm thiểu **MTTR - Mean Time To Recovery**). Trong môi trường phân tán (Microservices), **tuyệt đối không được đoán mò hoặc khởi động lại bừa bãi** các máy chủ, bởi việc restart khi chưa hiểu rõ nguyên nhân có thể làm xóa sạch hiện trường vụ án (Logs/Memory state) và khiến lỗi tái diễn trầm trọng hơn khi lượng request ứ đọng ập vào cùng lúc.

---

## 1. Sơ Đồ Kiến Trúc Hệ Thống Gặp Sự Cố

Hệ thống thanh toán của doanh nghiệp được triển khai theo kiến trúc chuỗi dịch vụ phân tán:

```text
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │                                   NGƯỜI DÙNG / KHÁCH HÀNG                              │
 └───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │ HTTP POST /api/checkout
                                             ▼
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ NGINX REVERSE PROXY (API GATEWAY) [Port 80]                                            │
 │ • Tiếp nhận traffic, cân bằng tải, ghi nhận access log kết hợp request_time            │
 └───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │ Proxy Pass (Forward)
                                             ▼
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ ORDER MICROSERVICE [Port 3001]                                                         │
 │ • Tiếp nhận đơn hàng, khởi tạo Trace Context (traceparent), gọi sang Payment Service   │
 └───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │ HTTP POST /api/pay (Context Propagation)
                                             ▼
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ PAYMENT MICROSERVICE [Port 3002] ──► [DATABASE CONNECTION POOL]                        │
 │ • Xử lý khấu trừ tiền, xác thực giao dịch qua Database Connection                      │
 └────────────────────────────────────────────────────────────────────────────────────────┘

 ════════════════════════════ HẠ TẦNG QUAN SÁT (OBSERVABILITY) ════════════════════════════
   [Distributed Tracing]  OpenTelemetry SDK  ──►  Jaeger All-in-One (Port 16686 & 4318)
   [Centralized Logging]  Fluent Bit Agent    ──►  Grafana Loki Repository (Port 3100)
```

---

## 2. Quy Tắc Của Bài Case Study

Khác với các bài lab thông thường có hướng dẫn chi tiết từng lệnh gõ, bài Case Study này **chỉ chuẩn bị sẵn môi trường và hiện trường sự cố đang diễn ra**. Bạn phải tự mình đóng vai trò điều tra viên:

1. **Không đoán mò:** Dùng dữ liệu định lượng (Metrics, Traces, Logs) để chứng minh từng giả thiết.
2. **Tuân thủ quy trình 4 giai đoạn:**
   - **Giai đoạn 1 (Triage):** Tự gửi request khảo sát hiện trường, ghi nhận mã lỗi và độ trễ.
   - **Giai đoạn 2 (Pinpoint):** Dùng Jaeger Distributed Tracing để cô lập dịch vụ và công đoạn (span) gây nghẽn.
   - **Giai đoạn 3 (Root Cause):** Dùng LogQL / Centralized Logging trên Loki để bắt trọn Exception và cấu hình sai lệch.
   - **Giai đoạn 4 (Mitigate & Post-Mortem):** Tiến hành Hotfix, chứng minh hệ thống đã hồi phục 100% và ghi chép Post-Mortem 5-Whys.

Bấm **Start** để bước vào phòng trực chiến và bắt đầu giải cứu hệ thống!
