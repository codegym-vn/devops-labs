# Lab 37: Xây Dựng Hệ Thống Centralized Logging

Trong kiến trúc hệ thống phân tán (Microservices & Multi-Node Cluster), mỗi dịch vụ ghi log vào các tệp tin hoặc container riêng lẻ. Khi một sự cố giao dịch xảy ra (ví dụ: khách hàng thanh toán bị trừ tiền nhưng không nhận được đơn hàng), kỹ sư vận hành sẽ phải SSH vào từng máy chủ, mở đồng thời hàng chục cửa sổ terminal và sử dụng lệnh **tail -f** hoặc **grep** thủ công. Cách tiếp cận phân mảnh này làm tăng đột biến thời gian phục hồi sự cố (MTTR) và hoàn toàn bất khả thi ở quy mô hàng trăm container.

Để giải quyết triệt để thách thức trên, các tổ chức công nghệ áp dụng mô hình **Centralized Logging (Hệ thống quản lý nhật ký tập trung)**: toàn bộ log từ Web Gateway, Backend Services, cơ sở dữ liệu và hệ điều hành được tự động thu thập, chuẩn hóa cấu trúc, gắn nhãn định danh và chuyển tiếp về một kho lưu trữ tập trung duy nhất theo thời gian thực.

---

## 1. Kiến Trúc Pipeline Centralized Logging Chuẩn Doanh Nghiệp

Hệ thống trong bài thực hành sử dụng **Fluent Bit** (dự án mã nguồn mở trực thuộc CNCF, được viết bằng C với hiệu năng xử lý hàng trăm nghìn log/giây và tiêu tốn chưa đến 50MB RAM) đóng vai trò tác tử thu thập và xử lý (Log Collector & Processor), kết hợp cùng **Grafana Loki** đóng vai trò kho lưu trữ nhật ký tập trung:

```text
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                               NGUỒN PHÁT SINH NHẬT KÝ                            │
 │                                                                                  │
 │   ┌──────────────────────────┐             ┌──────────────────────────┐          │
 │   │      NGINX GATEWAY       │             │    ORDER MICROSERVICE    │          │
 │   │                          │             │                          │          │
 │   │  Access Log (Combined)   │             │  Application Log (JSON)  │          │
 │   └────────────┬─────────────┘             └────────────┬─────────────┘          │
 └────────────────┼────────────────────────────────────────┼────────────────────────┘
                  │                                        │
                  ▼                                        ▼
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                         FLUENT BIT LOG PIPELINE PROCESSOR                        │
 │                                                                                  │
 │   [INPUT]  ──►  [PARSER]        ──►  [FILTER]          ──►  [ROUTING / OUTPUT]   │
 │   Tail tệp      Nginx Regex &        Record Modifier        Định tuyến theo Tag  │
 │   log apps      JSON Decoders        Gắn env, cluster       HTTP POST Push       │
 │                                      Che dữ liệu nhạy cảm                        │
 └───────────────────────────────────────────────────┬──────────────────────────────┘
                                                     │
                                                     ▼ HTTP Push /loki/api/v1/push
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │                    GRAFANA LOKI (CENTRALIZED LOG REPOSITORY)                     │
 │                                                                                  │
 │ • Lưu trữ các Log Stream nén theo chuỗi thời gian                                │
 │ • Index siêu nhẹ theo metadata labels (app, service, environment, datacenter)    │
 │ • Động cơ truy vấn LogQL bóc tách sự cố xuyên suốt đa tầng dịch vụ (Correlated)  │
 └──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mục Tiêu Bạn Cần Đạt Được Trong Bài Lab Này

1. **Khảo sát nỗi đau phân mảnh dữ liệu:** Khởi chạy hệ thống đa nguồn log (Web Gateway định dạng chuỗi văn bản và Backend Service định dạng JSON) và phân tích các hạn chế của phương pháp xem log cục bộ truyền thống.
2. **Thiết kế Pipeline xử lý log với Fluent Bit:** Khai báo cấu hình toàn diện gồm 4 tầng cốt lõi: Input (Tail log), Parser (giải mã Nginx Combined và JSON), Filter (làm giàu metadata và che dấu thông tin nhạy cảm) và Buffer an toàn.
3. **Vận hành cụm lưu trữ tập trung Grafana Loki & Định tuyến:** Cấu hình Output định tuyến đa luồng từ Fluent Bit sang Loki, bảo đảm mỗi loại dịch vụ được gắn đúng nhãn phân loại tự động.
4. **Truy vết sự cố phân tán bằng LogQL:** Mô phỏng sự cố lỗi thanh toán xuyên tầng và thực hiện các câu truy vấn LogQL liên kết (Correlated Query) để truy vết toàn bộ vòng đời giao dịch từ Nginx Gateway vào sâu trong Order Service.

Nhấn **Next** để bắt đầu bước đầu tiên!
