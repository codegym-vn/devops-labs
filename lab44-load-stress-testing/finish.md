# Hoàn Thành Xuất Sắc Lab 44: Xây Dựng Kịch Bản Load & Stress Testing

Chúc mừng bạn đã hoàn thành bài thực hành chuyên sâu về **Kiểm Thử Tải Và Sức Chịu Đựng (Load & Stress Testing)** bằng công cụ k6!

---

## Những Năng Lực Cốt Lõi Bạn Đã Làm Chủ

1. **Testing as Code Với k6:** Làm chủ cấu trúc kịch bản kiểm thử tải bằng JavaScript ES6, tổ chức các Virtual Users (VUs) và vòng lặp thực thi độc lập cho từng người dùng ảo.
2. **Thiết Lập Đường Cơ Sở Hiệu Năng (Baseline):** Đo lường chính xác các chỉ số vàng của hệ thống ở trạng thái hoạt động bình thường, bao gồm Throughput (Requests/sec) và Latency bách phân vị (`p90`, `p95`, `p99`).
3. **Mô Hình Hóa Kịch Bản Stress Test Đa Giai Đoạn:** Sử dụng cấu hình `stages` để tăng tải theo bậc thang (Ramping Stages), qua đó tìm ra **Điểm gãy (Breaking Point)** của hệ thống khi vượt quá khả năng phục vụ của thread pool.
4. **Kiểm Chứng Khả Năng Tự Phục Hồi:** Đánh giá hành vi của dịch vụ khi lượng truy cập hạ nhiệt (Ramp-down), xác nhận hệ thống có thể tự cân bằng lại mà không cần can thiệp thủ công.
5. **Tự Động Hóa Quality Gate Trong CI/CD:** Sử dụng cơ chế `thresholds` để thiết lập cổng kiểm soát chất lượng tự động, ngăn chặn các đoạn mã gây suy giảm hiệu năng lọt vào môi trường Production.

---

## Bảng So Sánh Các Chỉ Số Hiệu Năng Quan Trọng

| Chỉ số | Ý nghĩa kỹ thuật | Ngưỡng khuyến nghị |
| :--- | :--- | :--- |
| **`http_req_duration` p(95)** | 95% số request hoàn thành trong thời gian này | < 300ms đối với API Web |
| **`http_req_duration` p(99)** | 99% số request hoàn thành trong thời gian này (Tail Latency) | < 500ms - 1s |
| **`http_req_failed` rate** | Tỷ lệ request thất bại (lỗi 4xx, 5xx hoặc timeout) | < 0.5% (Tải thường), < 2% (Stress test) |
| **Throughput (RPS)** | Số lượng request hệ thống phục vụ được mỗi giây | Phụ thuộc vào năng lực phần cứng và logic |

---

## Bước Tiếp Theo

Ở bài lab này, bạn đã nhìn thấy hiệu năng từ góc nhìn của **Client** (k6 đo thời gian gửi nhận). Nhưng khi điểm gãy xảy ra, điều gì đang thực sự diễn ra bên trong **Server** (CPU có chạm trần không? RAM có bị cạn kiệt? Database Pool bị nghẽn ở đâu?).

Hãy cùng bước sang bài thực hành tiếp theo:
**"Lab 45: Correlate Load Test Với Monitoring"** — kết nối luồng số liệu k6 thời gian thực sang Prometheus và Grafana, quan sát song song giữa tải người dùng và tài nguyên hạ tầng để cô lập chính xác nút thắt cổ chai!
