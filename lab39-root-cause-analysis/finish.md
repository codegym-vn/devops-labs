# Xin Chúc Mừng! Bạn Đã Giải Cứu Thành Công Sự Cố P1

Bạn đã xuất sắc hoàn thành bài **[Case Study] Root Cause Analysis** — một thử thách mô phỏng chân thực nhất công việc On-Call của một kỹ sư SRE / DevOps thực thụ trong môi trường phân tán quy mô lớn.

---

## 1. Nhìn Lại Hành Trình Điều Tra Đã Thực Hiện

Thay vì hoảng loạn khởi động lại máy chủ (Reboot & Pray) như các kỹ sư thiếu kinh nghiệm, bạn đã tuân thủ chặt chẽ chu trình điều tra khoa học:

| Giai đoạn | Hành động cụ thể | Công cụ sử dụng | Bằng chứng thu được |
| :--- | :--- | :--- | :--- |
| **1. Triage** | Kiểm tra endpoint `/api/checkout`, đo lường thời gian phản hồi và mã trạng thái. | `curl -w`, Health checks | Request bị nghẽn > 2s rồi trả về mã `504 Gateway Timeout`. |
| **2. Pinpoint** | Phân tích Waterfall Tracing, bóc tách cấu trúc Spans xuyên ranh giới mạng. | **Jaeger (OpenTelemetry)** | Loại trừ Nginx và Order Service; cô lập nút thắt nằm tại span `db_acquire_connection` của `payment-service`. Lấy được `trace_id`. |
| **3. Root Cause** | Dùng `trace_id` để truy vấn kho log tập trung có cấu trúc. | **Grafana Loki (LogQL)** | Bắt trọn stack trace `ConnectionPoolExhaustedError` và phát hiện `DB_POOL_MAX=2` trong cấu hình môi trường. |
| **4. Mitigate & Post-Mortem** | Hotfix tăng `DB_POOL_MAX=20`, khởi động lại dịch vụ và lập báo cáo sự cố 5-Whys. | Shell script, Benchmark test | 100% request thành công với mã 200 OK, latency < 100ms. Ngăn ngừa tái diễn với Action Items. |

---

## 2. Bài Học Xương Máu Về Observability

Sự cố vừa rồi đã chứng minh mối liên kết hữu cơ không thể tách rời giữa 3 trụ cột của Observability:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                              METRICS                                   │
 │                "Hệ thống của bạn CÓ VẤN ĐỀ!"                           │
 │                (Alert p99 > 2s, Error rate 38%)                        │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                              TRACES                                    │
 │                "Vấn đề đang nằm Ở ĐÂU?"                                │
 │                (payment-service -> db_acquire_connection)              │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                               LOGS                                     │
 │                "TẠI SAO vấn đề lại xảy ra?"                            │
 │                (ConnectionPoolExhaustedError: active=2, max=2)         │
 └────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Bước Tiếp Theo

Trải nghiệm thực chiến từ Case Study này chính là chìa khóa mở đường hoàn hảo cho bài thảo luận tiếp theo:
👉 **"Metrics nói gì, Logs nói gì, Traces nói gì?"**

Hãy chuyển sang bài tiếp theo để cùng đào sâu và đúc kết những nguyên tắc vàng trong việc thiết kế kiến trúc giám sát toàn diện cho doanh nghiệp!
